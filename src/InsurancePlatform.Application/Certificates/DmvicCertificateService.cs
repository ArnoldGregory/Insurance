using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Issues the official NTSA motor certificate for a completed purchase via
/// SCAPI's DMVICINTERMEDIARY interface. Two calls, both over the same
/// generic IScapiGatewayClient the M-Pesa/OTP features use:
///   1. issuance_type_c_cert (private car after payment SUCCESS) mints the
///      certificate - NTSA replies output.success=true with
///      output.callbackObj.issueCertificate.actualCNo/TransactionNo/Email.
///   2. get_certificate (CertificateNumber = actualCNo) fetches the issued
///      document; its raw response is stored on the purchase's
///      certificate-document row for download/display later.
/// Everything is best-effort: any failure is logged and the purchase keeps
/// its internally-generated HTML certificate (see
/// IPurchaseCertificationService.CompleteAndIssueAsync, which is where the
/// DMVIC attempt lives as a fallback-safe step).
/// </summary>
public class DmvicCertificateService : IDmvicCertificateService
{
    private const string InterfaceName = "DMVICINTERMEDIARY";

    private readonly IScapiGatewayClient _gatewayClient;
    private readonly IPurchaseRepository _purchaseRepository;
    private readonly DmvicOptions _options;
    private readonly ILoggerManager _logger;

    public DmvicCertificateService(
        IScapiGatewayClient gatewayClient,
        IPurchaseRepository purchaseRepository,
        IConfiguration configuration,
        ILoggerManager logger)
    {
        _gatewayClient = gatewayClient;
        _purchaseRepository = purchaseRepository;
        _options = configuration.GetSection("Dmvic").Get<DmvicOptions>() ?? new DmvicOptions();
        _logger = logger;
    }

    public async Task<DmvicIssueResult> IssueForPurchaseAsync(long purchaseId)
    {
        if (!_options.Enabled)
        {
            return new DmvicIssueResult { Issued = false, Message = "D-MVIC issuance is disabled." };
        }

        var payloadResult = await _purchaseRepository.GetDmvicDataAsync(purchaseId);
        if (!payloadResult.IsSuccess || payloadResult.Data is null)
        {
            return new DmvicIssueResult { Issued = false, Message = payloadResult.ResultMessage };
        }

        var data = payloadResult.Data;

        if (data.NtsaCertificateNo is not null)
        {
            return new DmvicIssueResult
            {
                Issued = true,
                CertificateNo = data.NtsaCertificateNo,
                TransactionNo = data.NtsaTransactionNo,
                Message = "D-MVIC certificate already issued for this purchase."
            };
        }

        if (string.IsNullOrWhiteSpace(data.RegNo))
        {
            return new DmvicIssueResult { Issued = false, Message = "Not a Motor purchase - no vehicle to certify." };
        }

        if (string.IsNullOrWhiteSpace(data.MemberCompanyId))
        {
            return new DmvicIssueResult
            {
                Issued = false,
                Message = $"Underwriter '{data.UnderwriterName}' has no NTSA member id configured (Underwriters.dmvic_code)."
            };
        }

        var externalRef = DateTime.Now.ToString("yyyyMMddHHmmssfff");
        var (requestType, typeOfCertificate) = ResolveIssuanceType(data.VehicleType);

        _logger.LogInfo(
            $"D-MVIC purchase_id={purchaseId}: issuing via {requestType}/{typeOfCertificate} for vehicle {data.RegNo}, ref={externalRef}.");

        var body = BuildIssuanceBody(data, requestType, typeOfCertificate, externalRef);

        if (_options.CheckDoubleIssuance)
        {
            var doubleIssuance = await CheckDoubleIssuanceAsync(data, purchaseId, externalRef);
            if (doubleIssuance is not null)
            {
                return doubleIssuance;
            }
        }

        if (_options.ValidateBeforeIssue)
        {
            var validateResult = await ValidateAsync(data, purchaseId, requestType, typeOfCertificate, externalRef);
            if (validateResult is not null)
            {
                return validateResult;
            }
        }

        var issuanceResponse = await _gatewayClient.InvokeAsync(
            new ScapiMessageRoute
            {
                Interface = InterfaceName,
                RequestType = requestType,
                ExternalRefNumber = externalRef
            },
            body);

        if (issuanceResponse is null)
        {
            _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: gateway returned no response for the issuance call.");
            return new DmvicIssueResult { Issued = false, Message = "Gateway returned no response for D-MVIC issuance." };
        }

        var output = (issuanceResponse["error_desc"] as JsonObject)?["output"] as JsonObject;
        if (output is null)
        {
            var errorDescription = ExtractFlatError(issuanceResponse);
            _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: unexpected gateway response (ref={externalRef}): {issuanceResponse.ToJsonString()}");
            return new DmvicIssueResult { Issued = false, Message = errorDescription };
        }

        var successText = output["success"]?.ToString();
        if (successText is "true" or "True")
        {
            var issueCertificate = (output["callbackObj"] as JsonObject)?["issueCertificate"] as JsonObject;
            var certNo = issueCertificate?["actualCNo"]?.ToString();
            var transactionNo = issueCertificate?["TransactionNo"]?.ToString();
            var certEmail = issueCertificate?["Email"]?.ToString();

            if (string.IsNullOrWhiteSpace(certNo))
            {
                _logger.LogWarn(
                    $"D-MVIC purchase_id={purchaseId}: NTSA reported success but returned no actualCNo - certificate may be pending manual approval. Response: {output.ToJsonString()}");
                return new DmvicIssueResult { Issued = false, Message = "NTSA did not return a certificate number yet." };
            }

            _logger.LogInfo(
                $"D-MVIC purchase_id={purchaseId}: NTSA issued certificate {certNo} (transaction {transactionNo}), email {certEmail}.");

            var certDataRaw = await FetchCertificateAsync(purchaseId, certNo, externalRef);

            var saveResult = await _purchaseRepository.SaveDmvicResultAsync(
                purchaseId, certNo, transactionNo, certEmail, null, certDataRaw);

            if (!saveResult.IsSuccess)
            {
                _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: could not persist NTSA certificate {certNo}: {saveResult.ResultMessage}");
                return new DmvicIssueResult
                {
                    Issued = false,
                    CertificateNo = certNo,
                    TransactionNo = transactionNo,
                    Message = saveResult.ResultMessage
                };
            }

            return new DmvicIssueResult
            {
                Issued = true,
                CertificateNo = certNo,
                TransactionNo = transactionNo,
                Message = saveResult.ResultMessage
            };
        }

        // Failure - extract the NTSA error reason (usually output.Error[].errorText).
        var reason = ExtractErrorReason(output);
        _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: NTSA issuance rejected (ref={externalRef}): {reason}");
        return new DmvicIssueResult { Issued = false, Message = reason };
    }

    private (string RequestType, string TypeOfCertificate) ResolveIssuanceType(string? vehicleType)
    {
        var key = vehicleType?.Trim().ToUpperInvariant() ?? string.Empty;
        if (!string.IsNullOrWhiteSpace(key) &&
            _options.VehicleTypeMap.TryGetValue(key, out var mapping))
        {
            var parts = mapping.Split('|', 2, StringSplitOptions.TrimEntries);
            if (parts.Length == 2 && !string.IsNullOrWhiteSpace(parts[0]))
            {
                return (parts[0], parts[1]);
            }
        }

        return (_options.RequestType, _options.TypeOfCertificate);
    }

    private JsonObject BuildIssuanceBody(PurchaseDmvicData data, string requestType, string typeOfCertificate, string externalRef)
    {
        var phoneNumber = string.IsNullOrWhiteSpace(_options.NotificationPhoneNumber)
            ? data.ClientPhone ?? string.Empty
            : _options.NotificationPhoneNumber;
        var email = string.IsNullOrWhiteSpace(_options.NotificationEmail)
            ? data.ClientEmail ?? string.Empty
            : _options.NotificationEmail;
        var sumInsured = data.VehicleValue is decimal vehicleValue
            ? vehicleValue.ToString("F2")
            : data.PremiumAmount.ToString("F2");

        // NTSA expects a different field set per certificate type (mirrors
        // BIMADLINE's DMVICManager.IssueCertificate):
        //   a -> TypeOfCertificate (PSV / Taxi)
        //   b -> VehicleType + Tonnage, NO TypeOfCertificate (Commercial)
        //   c -> TypeOfCertificate only (Private Car) - unchanged from before
        //   d -> TypeOfCertificate + Tonnage (PSV / Motor Cycle)
        // Everything except type_b keeps the original TypeOfCertificate field
        // so the already-working private-car flow is byte-for-byte the same;
        // type_b/d only gain the extra fields NTSA needs for commercial cover.
        var certType = ResolveCertificateTypeLetter(requestType);

        var body = new JsonObject
        {
            ["Membercompanyid"] = data.MemberCompanyId
        };

        if (certType == "b")
        {
            body["VehicleType"] = typeOfCertificate;
        }
        else
        {
            body["TypeOfCertificate"] = typeOfCertificate;
        }

        body["Typeofcover"] = _options.TypeOfCover;
        body["Policyholder"] = data.Policyholder ?? string.Empty;
        body["policynumber"] = data.PolicyNumber ?? string.Empty;
        body["Commencingdate"] = data.StartDate.ToString("yyyy-MM-dd");
        body["Expiringdate"] = data.EndDate.ToString("yyyy-MM-dd");
        body["Registrationnumber"] = data.RegNo;
        body["Chassisnumber"] = data.ChassisNo ?? string.Empty;
        body["Phonenumber"] = NormalizeKenyanPhoneNumber(phoneNumber);
        body["Bodytype"] = data.PBodyType ?? string.Empty;

        if (certType is "b" or "d")
        {
            body["Tonnage"] = data.Tonnage?.ToString("0.##") ?? string.Empty;
        }

        body["Licensedtocarry"] = data.LicensedToCarry?.ToString() ?? string.Empty;
        body["Vehiclemake"] = data.Make ?? string.Empty;
        body["Vehiclemodel"] = data.Model ?? string.Empty;
        body["Enginenumber"] = data.EngineNo ?? string.Empty;
        body["Email"] = email;
        body["SumInsured"] = sumInsured;
        body["InsuredPIN"] = data.KraPin ?? string.Empty;
        body["Yearofmanufacture"] = data.YearOfManufacture?.ToString() ?? string.Empty;
        body["HudumaNumber"] = string.Empty;

        return body;
    }

    /// <summary>
    /// Extracts the certificate-type letter from a DMVIC request_type, e.g.
    /// "issuance_type_b_cert" / "validate_type_b_cert" -> "b". Falls back to
    /// "c" (the private-car set) when the request type is unrecognised.
    /// </summary>
    private static string ResolveCertificateTypeLetter(string requestType)
    {
        var parts = requestType.Split('_', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length >= 4 && parts[^1].Equals("cert", StringComparison.OrdinalIgnoreCase))
        {
            return parts[^2].ToLowerInvariant();
        }

        return "c";
    }

    /// <summary>
    /// Maps an issuance request_type to its pre-check variant, e.g.
    /// "issuance_type_c_cert" -> "validate_type_c_cert".
    /// </summary>
    private static string BuildValidateRequestType(string requestType)
        => requestType.StartsWith("issuance", StringComparison.OrdinalIgnoreCase)
            ? "validate" + requestType["issuance".Length..]
            : requestType;

    /// <summary>
    /// Runs NTSA's validate_double_insurance. Returns null when issuance may
    /// proceed, or a failed DmvicIssueResult when the vehicle already has cover.
    /// </summary>
    private async Task<DmvicIssueResult?> CheckDoubleIssuanceAsync(PurchaseDmvicData data, long purchaseId, string externalRef)
    {
        try
        {
            var response = await _gatewayClient.InvokeAsync(
                new ScapiMessageRoute
                {
                    Interface = InterfaceName,
                    RequestType = "validate_double_insurance",
                    ExternalRefNumber = externalRef
                },
                new JsonObject
                {
                    ["policystartdate"] = data.StartDate.ToString("dd/MM/yyyy"),
                    ["policyenddate"] = data.EndDate.ToString("dd/MM/yyyy"),
                    ["vehicleregistrationnumber"] = data.RegNo ?? string.Empty,
                    ["chassisnumber"] = data.ChassisNo ?? string.Empty
                });

            var output = (response?["error_desc"] as JsonObject)?["output"] as JsonObject;
            if (output is null)
            {
                _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: validate_double_insurance returned no usable output - proceeding with issuance.");
                return null;
            }

            if (output["success"]?.ToString() is "true" or "True")
            {
                var cover = (output["callbackObj"] as JsonObject)?["DoubleInsurance"] as JsonArray;
                var firstCover = cover?.OfType<JsonObject>().FirstOrDefault();
                var company = firstCover?["MemberCompanyName"]?.ToString();
                var endDate = firstCover?["CoverEndDate"]?.ToString();
                var message = string.IsNullOrWhiteSpace(company)
                    ? "The vehicle already has an active insurance cover."
                    : $"The vehicle has an active cover with {company}, expiring on {endDate}.";
                _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: double insurance detected - {message}");
                return new DmvicIssueResult { Issued = false, Message = message };
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError($"D-MVIC purchase_id={purchaseId}: validate_double_insurance failed; proceeding with issuance.", ex);
            return null;
        }
    }

    /// <summary>
    /// Runs NTSA's validate_type_*_cert pre-check. Returns null when issuance
    /// may proceed, or a failed DmvicIssueResult when NTSA rejects the data.
    /// </summary>
    private async Task<DmvicIssueResult?> ValidateAsync(PurchaseDmvicData data, long purchaseId, string requestType, string typeOfCertificate, string externalRef)
    {
        var validateRequestType = BuildValidateRequestType(requestType);
        var validateBody = BuildIssuanceBody(data, validateRequestType, typeOfCertificate, externalRef);

        var response = await _gatewayClient.InvokeAsync(
            new ScapiMessageRoute
            {
                Interface = InterfaceName,
                RequestType = validateRequestType,
                ExternalRefNumber = externalRef
            },
            validateBody);

        var output = (response?["error_desc"] as JsonObject)?["output"] as JsonObject;
        if (output is null)
        {
            var flat = response is null ? "Gateway returned no response for D-MVIC validation." : ExtractFlatError(response);
            _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: {validateRequestType} returned no usable output: {flat}");
            return new DmvicIssueResult { Issued = false, Message = flat };
        }

        if (output["success"]?.ToString() is "true" or "True")
        {
            return null;
        }

        var reason = ExtractErrorReason(output);
        _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: {validateRequestType} rejected (ref={externalRef}): {reason}");
        return new DmvicIssueResult { Issued = false, Message = reason };
    }

    private async Task<string?> FetchCertificateAsync(long purchaseId, string certNo, string externalRef)
    {
        try
        {
            var response = await _gatewayClient.InvokeAsync(
                new ScapiMessageRoute
                {
                    Interface = InterfaceName,
                    RequestType = "get_certificate",
                    ExternalRefNumber = externalRef
                },
                new JsonObject { ["CertificateNumber"] = certNo });

            if (response is null)
            {
                _logger.LogWarn($"D-MVIC purchase_id={purchaseId}: get_certificate returned no response for {certNo}.");
                return null;
            }

            var output = (response["error_desc"] as JsonObject)?["output"];
            var raw = output?.ToString() ?? response.ToJsonString();
            _logger.LogInfo($"D-MVIC purchase_id={purchaseId}: get_certificate for {certNo} (ref={externalRef}): {raw}");
            return raw;
        }
        catch (Exception ex)
        {
            _logger.LogError($"D-MVIC purchase_id={purchaseId}: get_certificate fetch failed for {certNo}.", ex);
            return null;
        }
    }

    private static string ExtractErrorReason(JsonObject output)
    {
        if (output["Error"] is JsonArray errors)
        {
            var texts = errors
                .OfType<JsonObject>()
                .Select(e => e["errorText"]?.ToString())
                .Where(t => !string.IsNullOrWhiteSpace(t))
                .ToList();

            if (texts.Count > 0)
            {
                return string.Join("; ", texts);
            }
        }

        return output["success"]?.ToString() ?? "NTSA rejected the issuance request.";
    }

    private static string ExtractFlatError(JsonObject response)
    {
        var errorDesc = response["error_desc"];
        if (errorDesc is JsonObject obj)
        {
            return obj["Message"]?.ToString()
                ?? obj["error_desc"]?.ToString()
                ?? "Gateway rejected the D-MVIC request.";
        }

        return "Gateway rejected the D-MVIC request.";
    }

    private static string NormalizeKenyanPhoneNumber(string phoneNumber)
    {
        var digitsOnly = Regex.Replace(phoneNumber, @"\D", string.Empty);
        var lastNineDigits = digitsOnly.Length >= 9 ? digitsOnly[^9..] : digitsOnly;
        return "254" + lastNineDigits;
    }
}