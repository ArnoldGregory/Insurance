using System.Text.Json.Nodes;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Certificates;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>
/// Endpoints Safaricom's Daraja API POSTs to directly when an M-Pesa
/// transaction completes - both the STK push result and the C2B Paybill
/// confirmation. These deliberately do NOT use a ChannelService token:
/// the payment gateway is the (pair) caller and can't join the app's
/// login flow, so both actions are [AllowAnonymous] and resolve the
/// target Payment purely by a reference the gateway echoes back
/// (CheckoutRequestID for STK, BillRefNumber/TransID for C2B). That
/// reference was stored at push time via usp_Payment_SetGatewayReference
/// (see PaymentsController.InitiateStkPush), so nothing client-supplied
/// is trusted for the lookup. Both actions are idempotent - Safaricom
/// retries until it gets a 200, and the resolve procedures in the DB
/// ignore duplicate callbacks for an already-terminal payment.
///
/// Security notes:
///  * Every call is logged with the source IP + full body for
///    reconciliation.
///  * A request that claims success for an unknown reference is still
///    answered 200 (Success=false) so the gateway stops retrying, and is
///    loud in the logs for an operator to reconcile.
///  * No customer data is returned in the response body.
/// </summary>
[ApiController]
[Route("api/mpesa/callback")]
[AllowAnonymous]
public class MpesaCallbackController : BaseApiController
{
    private const string ActorType = "GATEWAY_WEBHOOK";

    private readonly IPaymentRepository _paymentRepository;
    private readonly IPurchaseCertificationService _certificationService;
    private readonly ILoggerManager _logger;

    public MpesaCallbackController(
        IPaymentRepository paymentRepository,
        IPurchaseCertificationService certificationService,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _paymentRepository = paymentRepository;
        _certificationService = certificationService;
        _logger = logger;
    }

    /// <summary>Daraja STK push result callback - resolves the PENDING payment created at push time by CheckoutRequestID.</summary>
    /// <response code="200">Always 200 - status carried in the body; check Success.</response>
    [HttpPost("stk")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> StkCallback([FromBody] JsonObject? body)
    {
        var sourceIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        _logger.LogInfo($"M-Pesa STK callback received from {sourceIp} (ref={CorrelationRef}): {body?.ToJsonString() ?? "(empty body)"}");

        if (body is null)
        {
            return Ok(ApiResponse<object?>.Fail("Empty callback body.", CorrelationRef));
        }

        var callback = body["Body"]?["stkCallback"] as JsonObject;
        var checkoutRequestId = callback?["CheckoutRequestID"]?.GetValue<string>()?.Trim();
        var merchantRequestId = callback?["MerchantRequestID"]?.GetValue<string>()?.Trim();
        var resultCodeText = callback?["ResultCode"]?.ToString();
        var resultDesc = callback?["ResultDesc"]?.ToString() ?? "Unknown result description.";

        if (string.IsNullOrWhiteSpace(checkoutRequestId))
        {
            _logger.LogWarn($"M-Pesa STK callback (ref={CorrelationRef}) had no CheckoutRequestID; ignoring.");
            return Ok(ApiResponse<object?>.Fail("Callback has no CheckoutRequestID.", CorrelationRef));
        }

        if (!int.TryParse(resultCodeText, out var resultCode))
        {
            _logger.LogWarn($"M-Pesa STK callback (ref={CorrelationRef}) had unparseable ResultCode '{resultCodeText}'; ignoring.");
            return Ok(ApiResponse<object?>.Fail("Callback has an unparseable ResultCode.", CorrelationRef));
        }

        var status = resultCode == 0 ? "SUCCESS" : "FAILED";
        var mpesaReceipt = ReadMetadataValue(callback, "MpesaReceiptNumber");

        var result = await _paymentRepository.ResolveByGatewayReferenceAsync(
            checkoutRequestId, status, mpesaReceipt, ActorType, null);

        if (!result.IsSuccess || result.Data?.PaymentId is null)
        {
            _logger.LogWarn(
                $"M-Pesa STK callback (ref={CorrelationRef}) could NOT be resolved: checkout_request_id={checkoutRequestId}, merchant_request_id={merchantRequestId}, result_code={resultCode} ({resultDesc}), mpesa_receipt={mpesaReceipt}, resolver={result.ResultMessage}");
            return Ok(ApiResponse<object?>.Fail(result.ResultMessage, CorrelationRef));
        }

        // A callback that actually flipped the payment to SUCCESS completes the
        // purchase's certificate straight away (the same usp_Purchase_CompleteCert
        // the retry button and the background take-over worker call), so the
        // customer's wizard can show "Purchase Complete" immediately instead of
        // waiting up to the worker's poll interval. NotProcessed retries are left
        // to the worker - the cert is already generated by then.
        if (status == "SUCCESS" && !result.Data.NotProcessed && result.Data.PurchaseId is long purchaseId)
        {
            await CompleteCertAsync(purchaseId, result.Data.PaymentId.Value);
        }

        _logger.LogInfo(
            $"M-Pesa STK callback resolved (ref={CorrelationRef}): checkout_request_id={checkoutRequestId}, status={status}, mpesa_receipt={mpesaReceipt}, payment_id={result.Data.PaymentId}.");
        return Ok(ApiResponse<object?>.Ok(new { PaymentId = result.Data.PaymentId }, result.ResultMessage, CorrelationRef));
    }

    /// <summary>Daraja C2B Paybill confirmation - resolves by BillRefNumber (falls back to TransID).</summary>
    /// <response code="200">Always 200 - status carried in the body; check Success.</response>
    [HttpPost("confirmation")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Confirmation([FromBody] JsonObject? body)
    {
        var sourceIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        _logger.LogInfo($"M-Pesa C2B confirmation received from {sourceIp} (ref={CorrelationRef}): {body?.ToJsonString() ?? "(empty body)"}");

        if (body is null)
        {
            return Ok(ApiResponse<object?>.Fail("Empty confirmation body.", CorrelationRef));
        }

        var reference = body["BillRefNumber"]?.GetValue<string>()?.Trim() ?? body["TransID"]?.GetValue<string>()?.Trim();
        var transId = body["TransID"]?.GetValue<string>()?.Trim();
        var transAmount = body["TransAmount"]?.ToString();

        if (string.IsNullOrWhiteSpace(reference))
        {
            _logger.LogWarn($"M-Pesa C2B confirmation (ref={CorrelationRef}) had neither BillRefNumber nor TransID; ignoring.");
            return Ok(ApiResponse<object?>.Fail("Confirmation has no resolvable reference.", CorrelationRef));
        }

        var result = await _paymentRepository.ResolveByTransactionReferenceAsync(
            reference, "SUCCESS", transId, ActorType, null);

        if (!result.IsSuccess || result.Data?.PaymentId is null)
        {
            _logger.LogWarn(
                $"M-Pesa C2B confirmation (ref={CorrelationRef}) could NOT be resolved: reference={reference}, trans_id={transId}, trans_amount={transAmount}, resolver={result.ResultMessage}");
            return Ok(ApiResponse<object?>.Fail(result.ResultMessage, CorrelationRef));
        }

        // Same immediate certificate completion as the STK path - a C2B
        // confirmation is exactly as good as an STK success callback.
        if (!result.Data.NotProcessed && result.Data.PurchaseId is long purchaseId)
        {
            await CompleteCertAsync(purchaseId, result.Data.PaymentId.Value);
        }

        _logger.LogInfo(
            $"M-Pesa C2B confirmation resolved (ref={CorrelationRef}): reference={reference}, trans_id={transId}, trans_amount={transAmount}, status=SUCCESS, payment_id={result.Data.PaymentId}.");
        return Ok(ApiResponse<object?>.Ok(new { PaymentId = result.Data.PaymentId }, result.ResultMessage, CorrelationRef));
    }

    /// <summary>
    /// Completes a purchase's certificate after its payment resolves to
    /// SUCCESS. usp_Purchase_CompleteCert (inside the shared
    /// PurchaseCertificationService) is idempotent (already-GENERATED or
    /// not-PAID calls just return a result code without erroring), so this
    /// is safe for Safaricom retries too. The service also runs the
    /// best-effort NTSA official-certificate issuance that falls back to
    /// the internal certificate. Purely best-effort - if it fails, the
    /// background take-over worker picks the purchase up on its next poll,
    /// so the callback itself never returns an error for it.
    /// </summary>
    private async Task CompleteCertAsync(long purchaseId, long paymentId)
    {
        var completed = await _certificationService.CompleteAndIssueAsync(
            purchaseId, ActorType, paymentId);

        if (completed.IsSuccess)
        {
            _logger.LogInfo(
                $"Certificate completed for purchase_id={purchaseId} (ref={CorrelationRef}) via M-Pesa callback (payment_id={paymentId}).");
        }
        else
        {
            _logger.LogWarn(
                $"Certificate completion skipped for purchase_id={purchaseId} (ref={CorrelationRef}) via M-Pesa callback (payment_id={paymentId}): {completed.ResultMessage} - the background take-over worker will retry if still applicable.");
        }
    }

    private static string? ReadMetadataValue(JsonObject? callback, string name)
    {
        var items = callback?["CallbackMetadata"]?["Item"] as JsonArray;
        if (items is null)
        {
            return null;
        }

        foreach (var item in items)
        {
            if (item is not JsonObject obj || obj["Name"]?.GetValue<string>() != name)
            {
                continue;
            }

            var value = obj["Value"];
            return value?.ToString();
        }

        return null;
    }
}