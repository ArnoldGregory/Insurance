using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Certificates;

/// <inheritdoc cref="IUnderwriterCertificateService"/>
public class UnderwriterCertificateService : IUnderwriterCertificateService
{
    private const string DirectLineInterface = "DIRECTLINE";
    private const string DirectLineRequestType = "DirectLineCertificateGeneration";

    private readonly IDmvicCertificateService _dmvicCertificateService;
    private readonly IUnderwriterCertificateRepository _repository;
    private readonly IPurchaseRepository _purchaseRepository;
    private readonly IScapiGatewayClient _gatewayClient;
    private readonly ICertificateFileStore _fileStore;
    private readonly UnderwriterIntegrationOptions _options;
    private readonly ILoggerManager _logger;

    public UnderwriterCertificateService(
        IDmvicCertificateService dmvicCertificateService,
        IUnderwriterCertificateRepository repository,
        IPurchaseRepository purchaseRepository,
        IScapiGatewayClient gatewayClient,
        ICertificateFileStore fileStore,
        IConfiguration configuration,
        ILoggerManager logger)
    {
        _dmvicCertificateService = dmvicCertificateService;
        _repository = repository;
        _purchaseRepository = purchaseRepository;
        _gatewayClient = gatewayClient;
        _fileStore = fileStore;
        _options = configuration.GetSection(UnderwriterIntegrationOptions.SectionName).Get<UnderwriterIntegrationOptions>()
                   ?? new UnderwriterIntegrationOptions();
        _logger = logger;
    }

    public async Task<DmvicIssueResult> IssueForPurchaseAsync(long purchaseId)
    {
        if (!_options.AnyEnabled)
        {
            return await _dmvicCertificateService.IssueForPurchaseAsync(purchaseId);
        }

        var dataResult = await _repository.GetPurchaseDataAsync(purchaseId);
        if (!dataResult.IsSuccess || dataResult.Data is null)
        {
            return new DmvicIssueResult { Issued = false, Message = dataResult.ResultMessage };
        }

        var data = dataResult.Data;

        if (_options.DirectLine.Enabled && UnderwriterIntegrationOptions.NameMatches(data.UnderwriterName, _options.DirectLine.NameContains))
        {
            return await RequestDirectLineAsync(data);
        }

        if (_options.Amaco.Enabled && UnderwriterIntegrationOptions.NameMatches(data.UnderwriterName, _options.Amaco.NameContains))
        {
            return await RecordAwaitingCallbackAsync(data, UnderwriterIntegrations.Amaco);
        }

        if (_options.Definite.Enabled && UnderwriterIntegrationOptions.NameMatches(data.UnderwriterName, _options.Definite.NameContains))
        {
            return await RecordAwaitingCallbackAsync(data, UnderwriterIntegrations.Definite);
        }

        return await _dmvicCertificateService.IssueForPurchaseAsync(purchaseId);
    }

    public async Task<UnderwriterCallbackResult> CompleteFromCallbackAsync(UnderwriterCallback callback)
    {
        var found = await _repository.FindForCallbackAsync(callback.Integration, callback.ExternalRef, callback.PolicyNumber);
        if (!found.IsSuccess || found.Data is null)
        {
            _logger.LogWarn(
                $"{callback.Integration} certificate callback could not be matched (external_ref={callback.ExternalRef}, policy={callback.PolicyNumber}): {found.ResultMessage}");
            return new UnderwriterCallbackResult { Accepted = false, Message = found.ResultMessage };
        }

        var request = found.Data;

        if (!callback.Success || string.IsNullOrWhiteSpace(callback.CertificateNo))
        {
            var error = callback.ErrorMessage ?? "Insurer reported the certificate was not issued.";
            await _repository.UpdateRequestAsync(
                request.RequestId, UnderwriterCertStatus.Failed, callbackPayload: callback.RawPayload, errorMessage: error);
            _logger.LogWarn($"{callback.Integration} certificate FAILED for purchase_id={request.PurchaseId}: {error}");
            return new UnderwriterCallbackResult { Accepted = true, PurchaseId = request.PurchaseId, Message = "Failure recorded." };
        }

        var certNo = callback.CertificateNo.Trim();
        var policyNo = callback.PolicyNumber?.Trim();

        // Same recording path as an NTSA/DMVIC certificate, so every screen,
        // the certificate lookup and the PDF download treat it identically.
        var save = await _purchaseRepository.SaveDmvicResultAsync(
            request.PurchaseId, certNo, policyNo ?? request.ExternalRef, null, callback.CertificateUrl, callback.RawPayload);

        if (!save.IsSuccess && save.ResultCode != ResultCodes.Duplicate)
        {
            _logger.LogWarn($"{callback.Integration} certificate {certNo} for purchase_id={request.PurchaseId} could not be saved: {save.ResultMessage}");
            await _repository.UpdateRequestAsync(
                request.RequestId, null, callbackPayload: callback.RawPayload, certNo: certNo, policyNo: policyNo,
                certUrl: callback.CertificateUrl, errorMessage: save.ResultMessage);
            return new UnderwriterCallbackResult { Accepted = false, PurchaseId = request.PurchaseId, Message = save.ResultMessage };
        }

        if (!string.IsNullOrWhiteSpace(callback.CertificateUrl))
        {
            await _fileStore.SaveFromUrlAsync(request.PurchaseId, certNo, callback.CertificateUrl);
        }

        await _repository.UpdateRequestAsync(
            request.RequestId, UnderwriterCertStatus.Issued, callbackPayload: callback.RawPayload,
            certNo: certNo, policyNo: policyNo, certUrl: callback.CertificateUrl);

        _logger.LogInfo($"{callback.Integration} certificate {certNo} recorded for purchase_id={request.PurchaseId}.");
        return new UnderwriterCallbackResult { Accepted = true, PurchaseId = request.PurchaseId, Message = "Certificate recorded." };
    }

    private async Task<DmvicIssueResult> RecordAwaitingCallbackAsync(UnderwriterCertPurchaseData data, string integration)
    {
        if (!string.IsNullOrWhiteSpace(data.NtsaCertificateNo))
        {
            return new DmvicIssueResult { Issued = true, CertificateNo = data.NtsaCertificateNo, Message = "Certificate already recorded." };
        }

        var externalRef = NewExternalRef();
        var created = await _repository.CreateRequestAsync(
            data.PurchaseId, integration, externalRef, UnderwriterCertStatus.AwaitingCallback, null);

        var message = created.IsSuccess
            ? $"{integration}: certificate is issued by the insurer and will arrive by callback (ref {externalRef})."
            : $"{integration}: {created.ResultMessage}";

        _logger.LogInfo($"purchase_id={data.PurchaseId}: {message}");
        return new DmvicIssueResult { Issued = false, TransactionNo = externalRef, Message = message };
    }

    private async Task<DmvicIssueResult> RequestDirectLineAsync(UnderwriterCertPurchaseData data)
    {
        var options = _options.DirectLine;

        if (!string.IsNullOrWhiteSpace(data.NtsaCertificateNo))
        {
            return new DmvicIssueResult { Issued = true, CertificateNo = data.NtsaCertificateNo, Message = "Certificate already recorded." };
        }

        if (string.IsNullOrWhiteSpace(data.RegNo))
        {
            return new DmvicIssueResult { Issued = false, Message = "Not a Motor purchase - no vehicle to certify." };
        }

        if (string.IsNullOrWhiteSpace(options.AgentCode) || string.IsNullOrWhiteSpace(options.ApiCode))
        {
            _logger.LogWarn($"DirectLine purchase_id={data.PurchaseId}: UnderwriterIntegrations:DirectLine AgentCode/ApiCode not configured - not posted.");
            return new DmvicIssueResult { Issued = false, Message = "DirectLine AgentCode/ApiCode are not configured." };
        }

        if (!options.TryResolveVehicleType(data.VehicleType, out var vehicleType))
        {
            _logger.LogWarn($"DirectLine purchase_id={data.PurchaseId}: vehicle class '{data.VehicleType}' has no DirectLine vehicletype mapping - not posted.");
            return new DmvicIssueResult { Issued = false, Message = $"Vehicle class '{data.VehicleType}' has no DirectLine vehicle type mapping." };
        }

        var period = DirectLineIntegrationOptions.PeriodCode(data.DurationDays);
        if (period is null)
        {
            return new DmvicIssueResult { Issued = false, Message = $"A {data.DurationDays}-day cover has no DirectLine period code." };
        }

        var externalRef = NewExternalRef();
        var body = BuildDirectLineBody(data, options, vehicleType, period, externalRef);

        var created = await _repository.CreateRequestAsync(
            data.PurchaseId, UnderwriterIntegrations.DirectLine, externalRef, UnderwriterCertStatus.Pending, body.ToJsonString());

        if (!created.IsSuccess || created.Data is not long requestId)
        {
            return new DmvicIssueResult { Issued = false, Message = $"DirectLine: {created.ResultMessage}" };
        }

        JsonObject? response;
        try
        {
            response = await _gatewayClient.InvokeAsync(
                new ScapiMessageRoute
                {
                    Interface = DirectLineInterface,
                    RequestType = DirectLineRequestType,
                    ExternalRefNumber = externalRef
                },
                body);
        }
        catch (Exception ex)
        {
            _logger.LogError($"DirectLine purchase_id={data.PurchaseId}: gateway call failed (ref={externalRef}).", ex);
            await _repository.UpdateRequestAsync(requestId, UnderwriterCertStatus.Failed, errorMessage: ex.Message);
            return new DmvicIssueResult { Issued = false, Message = "DirectLine gateway call failed." };
        }

        if (response is null)
        {
            await _repository.UpdateRequestAsync(requestId, UnderwriterCertStatus.Failed, errorMessage: "No response from gateway.");
            return new DmvicIssueResult { Issued = false, Message = "Gateway returned no response for DirectLine." };
        }

        var raw = response.ToJsonString();
        // BIMADLINE reads output.message and treats "posted successfully" as accepted.
        var output = response["output"] as JsonObject ?? (response["error_desc"] as JsonObject)?["output"] as JsonObject;
        var message = output?["message"]?.ToString() ?? string.Empty;
        var accepted = message.Replace(" ", string.Empty).Contains("postedsuccessfully", StringComparison.OrdinalIgnoreCase);

        if (accepted)
        {
            await _repository.UpdateRequestAsync(requestId, UnderwriterCertStatus.Posted, responsePayload: raw);
            _logger.LogInfo($"DirectLine purchase_id={data.PurchaseId}: posted (ref={externalRef}) - certificate will arrive by callback.");
            return new DmvicIssueResult
            {
                Issued = false,
                TransactionNo = externalRef,
                Message = "DirectLine accepted the request - certificate will arrive by callback."
            };
        }

        var error = string.IsNullOrWhiteSpace(message) ? "DirectLine did not accept the request." : message;
        await _repository.UpdateRequestAsync(requestId, UnderwriterCertStatus.Failed, responsePayload: raw, errorMessage: error);
        _logger.LogWarn($"DirectLine purchase_id={data.PurchaseId}: rejected (ref={externalRef}): {raw}");
        return new DmvicIssueResult { Issued = false, Message = error };
    }

    private static JsonObject BuildDirectLineBody(
        UnderwriterCertPurchaseData data, DirectLineIntegrationOptions options, string vehicleType, string period, string externalRef)
    {
        var email = string.IsNullOrWhiteSpace(options.NotificationEmail) ? data.ClientEmail ?? string.Empty : options.NotificationEmail;
        var phone = string.IsNullOrWhiteSpace(options.NotificationPhoneNumber) ? data.ClientPhone ?? string.Empty : options.NotificationPhoneNumber;
        var carry = data.LicensedToCarry?.ToString() ?? string.Empty;

        // Field-for-field the message_body BIMADLINE posts in RePurchaseInsurance.
        // BIMADLINE sends licensed-to-carry as both cubicCapacity and
        // carryCapacity - kept identical since that is what DirectLine accepts today.
        return new JsonObject
        {
            ["vehicletype"] = vehicleType,
            ["bodytype"] = data.PBodyType ?? string.Empty,
            ["transactionCode"] = externalRef,
            ["coverStartDate"] = data.StartDate.ToString("yyyy-MM-dd"),
            ["period"] = period,
            ["coverType"] = options.CoverType,
            ["yrManft"] = data.YearOfManufacture?.ToString() ?? string.Empty,
            ["plateNumber"] = data.RegNo ?? string.Empty,
            ["carmake"] = data.Make ?? string.Empty,
            ["cubicCapacity"] = carry,
            ["chasisNo"] = data.ChassisNo ?? string.Empty,
            ["carryCapacity"] = carry,
            ["customerFullName"] = data.Policyholder ?? string.Empty,
            ["requestType"] = "NEW",
            ["amount"] = 0,
            ["agentCode"] = options.AgentCode,
            ["paymentMode"] = options.PaymentMode,
            ["tonnage"] = data.Tonnage?.ToString("0.##") ?? string.Empty,
            ["idNumber"] = data.IdNo ?? string.Empty,
            ["email"] = email,
            ["msisdn"] = NormalizeKenyanPhoneNumber(phone),
            ["postalAddress"] = options.PostalAddress,
            ["clientType"] = options.ClientType,
            ["town"] = options.Town,
            ["pin"] = data.KraPin ?? string.Empty,
            ["api_code"] = options.ApiCode
        };
    }

    private static string NewExternalRef() => DateTime.Now.ToString("yyyyMMddHHmmssfff");

    private static string NormalizeKenyanPhoneNumber(string phoneNumber)
    {
        var digitsOnly = Regex.Replace(phoneNumber, @"\D", string.Empty);
        if (digitsOnly.Length == 0)
        {
            return string.Empty;
        }
        var lastNineDigits = digitsOnly.Length >= 9 ? digitsOnly[^9..] : digitsOnly;
        return "254" + lastNineDigits;
    }
}
