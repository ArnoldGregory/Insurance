using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Payments;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Payments;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Payment attempts against a purchase.</summary>
// UpdateStatus is meant to be called from a payment gateway callback (see
// its own doc comment) - restricted to ChannelService plus back-office
// staff (a real webhook would authenticate as a ChannelService account via
// /api/auth/channel-login, same as USSD/WhatsApp). Create/GetByPurchase are
// [Authorize]-only for now; tightening these to verify the caller actually
// owns the underlying purchase is a reasonable future improvement, not done
// in this pass. InitiateStkPush is the alternative to plain Create+manual-
// Paybill - it does both (records the Payment as PENDING, then pushes) in
// one call, and is also [Authorize]-only since Client/Agent/ChannelService
// are all legitimate callers.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentsController : BaseApiController
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IMpesaStkPushService _stkPushService;
    private readonly ILoggerManager _logger;

    public PaymentsController(
        IPaymentRepository paymentRepository,
        IMpesaStkPushService stkPushService,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _paymentRepository = paymentRepository;
        _stkPushService = stkPushService;
        _logger = logger;
    }

    /// <summary>Records a payment attempt as PENDING.</summary>
    // For USSD/M-Pesa STK push, call this immediately when the push is
    // initiated - the session ends before the customer necessarily
    // completes it, so completion is confirmed later via UpdateStatus.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreatePaymentRequest request)
    {
        var actorType = CurrentRoleCode switch
        {
            RoleCodes.Client => "CLIENT",
            RoleCodes.ChannelService => "CHANNEL_SERVICE",
            _ => "USER"
        };

        var result = await _paymentRepository.CreateAsync(
            request.PurchaseId, request.Amount, request.Method, request.PayerPhone,
            request.TransactionReference, actorType, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Payment create failed for purchase_id={request.PurchaseId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Payment created: payment_id={result.Data}, purchase_id={request.PurchaseId}.");
        return Success(new { PaymentId = result.Data }, result.ResultMessage);
    }

    /// <summary>Records a Payment as PENDING and pushes an M-Pesa STK prompt to the customer's phone - the alternative to paying manually via Paybill with the account reference from Purchase Create.</summary>
    // The Payment row is created FIRST and stays PENDING no matter what the
    // push itself returns - "the push was sent" and "the customer entered
    // their PIN correctly" are two different things. Actual confirmation
    // only ever arrives later via Safaricom's own Daraja callback, resolved
    // through PUT /api/payments/{id}/status (see that action's own doc
    // comment) - never from this call's response. If the push itself fails
    // to send (network issue, gateway rejection), the Payment row is left
    // exactly as-is so the customer can still complete payment manually via
    // Paybill using the same account reference - nothing is rolled back.
    /// <response code="200">Always 200 - check Success in the body. A 200/Success here only means the push was delivered, not that payment succeeded.</response>
    [HttpPost("stk-push")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> InitiateStkPush([FromBody] InitiateStkPushRequest request)
    {
        var actorType = CurrentRoleCode switch
        {
            RoleCodes.Client => "CLIENT",
            RoleCodes.ChannelService => "CHANNEL_SERVICE",
            _ => "USER"
        };

        var paymentResult = await _paymentRepository.CreateAsync(
            request.PurchaseId, request.Amount, "MPESA", request.PhoneNumber, null, actorType, CurrentUserId);

        if (!paymentResult.IsSuccess || paymentResult.Data is null)
        {
            _logger.LogWarn($"STK push aborted - payment record create failed for purchase_id={request.PurchaseId}: {paymentResult.ResultMessage}");
            return BusinessFailure(paymentResult.ResultMessage);
        }

        var paymentId = paymentResult.Data.Value;
        var externalRefNumber = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");

        var pushResult = await _stkPushService.InitiatePushAsync(request.PhoneNumber, request.Amount, request.AccountReference, externalRefNumber);

        // Either way, the Payment record was already created successfully
        // above - that's the actual "did this call succeed" outcome, so
        // this always returns Success (200/success:true) with a
        // structured PaymentId, never BusinessFailure. PushSent tells the
        // caller whether the phone prompt itself went out; if it's false,
        // the caller still has payment_id/AccountReference to fall back to
        // manual Paybill payment - nothing about the Payment row changes
        // either way, it's PENDING regardless until a real callback resolves it.
        if (!pushResult.Success)
        {
            _logger.LogWarn($"STK push not accepted for payment_id={paymentId}, purchase_id={request.PurchaseId}: {pushResult.Message}");
            return Success(
                new { PaymentId = paymentId, PushSent = false, PushMessage = pushResult.Message },
                $"Payment recorded as pending (payment_id={paymentId}), but the STK push could not be sent: {pushResult.Message} The customer can still pay via Paybill using account reference {request.AccountReference}.");
        }

        _logger.LogInfo($"STK push sent: payment_id={paymentId}, purchase_id={request.PurchaseId}, merchant_request_id={pushResult.MerchantRequestId}, checkout_request_id={pushResult.CheckoutRequestId}.");
        return Success(
            new { PaymentId = paymentId, PushSent = true, pushResult.MerchantRequestId, pushResult.CheckoutRequestId },
            pushResult.Message);
    }

    /// <summary>Confirms or fails a payment - on SUCCESS also flips the purchase's payment_status to PAID.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.ChannelService},{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpPut("{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateStatus(long id, [FromBody] UpdatePaymentStatusRequest request)
    {
        var actorType = CurrentRoleCode == RoleCodes.ChannelService ? "CHANNEL_SERVICE" : "USER";

        var result = await _paymentRepository.UpdateStatusAsync(id, request.Status, request.TransactionReference, actorType, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Payment status changed: payment_id={id}, status={request.Status}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Lists every payment attempt against a purchase, most recent first.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("by-purchase/{purchaseId}")]
    [ProducesResponseType(typeof(ApiResponse<List<Payment>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetByPurchase(long purchaseId)
    {
        var result = await _paymentRepository.GetByPurchaseAsync(purchaseId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Payment_GetByPurchase returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard stat-card counts (by status) plus total amount collected - an Agent sees only payments on purchases they personally executed.</summary>
    // Same purchasedByUserId scoping convention as PurchasesController.GetSummary.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<PaymentDashboardSummary>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary()
    {
        long? purchasedByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _paymentRepository.GetSummaryAsync(purchasedByUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Payment_GetSummary returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }
}
