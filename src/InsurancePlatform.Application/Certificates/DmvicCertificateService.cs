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

        var body = BuildIssuanceBody(data, typeOfCertificate, externalRef);

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

    private JsonObject BuildIssuanceBody(PurchaseDmvicData data, string typeOfCertificate, string externalRef)
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

        return new JsonObject
        {
            ["Membercompanyid"] = data.MemberCompanyId,
            ["TypeOfCertificate"] = typeOfCertificate,
            ["Typeofcover"] = _options.TypeOfCover,
            ["Policyholder"] = data.Policyholder ?? string.Empty,
            ["policynumber"] = data.PolicyNumber ?? string.Empty,
            ["Commencingdate"] = data.StartDate.ToString("yyyy-MM-dd"),
            ["Expiringdate"] = data.EndDate.ToString("yyyy-MM-dd"),
            ["Registrationnumber"] = data.RegNo,
            ["Chassisnumber"] = data.ChassisNo ?? string.Empty,
            ["Phonenumber"] = NormalizeKenyanPhoneNumber(phoneNumber),
            ["Bodytype"] = data.PBodyType ?? string.Empty,
            ["Licensedtocarry"] = data.LicensedToCarry?.ToString() ?? string.Empty,
            ["Vehiclemake"] = data.Make ?? string.Empty,
            ["Vehiclemodel"] = data.Model ?? string.Empty,
            ["Enginenumber"] = data.EngineNo ?? string.Empty,
            ["Email"] = email,
            ["SumInsured"] = sumInsured,
            ["InsuredPIN"] = data.KraPin ?? string.Empty,
            ["Yearofmanufacture"] = data.YearOfManufacture?.ToString() ?? string.Empty,
            ["HudumaNumber"] = string.Empty
        };
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