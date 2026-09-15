using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Purchases;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Api.Controllers;

/// <summary>The central purchase flow - buys a Motor or manual-quote policy, and accrues agent commission inline.</summary>
// Create is [Authorize]-only rather than gated by a single policy, because
// three different kinds of caller are all legitimate: a Client buying for
// themselves, staff (Agent/AgentAdmin/SupportAgent) buying ON BEHALF of a
// client, and a USSD/WhatsApp channel-service account. Only the "on
// behalf" case actually needs PURCHASE_ON_BEHALF - checked manually inside
// Create (CallerHasPermission) rather than via [Authorize(Policy=)], since
// that attribute would also block Client/ChannelService callers who hold
// no permission claims at all by design (see RolePermissions seed data).
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PurchasesController : BaseApiController
{
    private readonly IPurchaseRepository _purchaseRepository;
    private readonly IClientRepository _clientRepository;
    private readonly ILoggerManager _logger;
    private readonly string _paybillNumber;

    public PurchasesController(
        IPurchaseRepository purchaseRepository,
        IClientRepository clientRepository,
        ILoggerManager logger,
        IConfiguration configuration,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _purchaseRepository = purchaseRepository;
        _clientRepository = clientRepository;
        _logger = logger;
        // Fixed environment setting (appsettings.json Mpesa:BusinessShortCode),
        // same "read config directly, no proc round-trip" approach
        // OtpNotificationSender uses for ScapiGateway:LogoUrl - not
        // purchase-specific data, so it doesn't belong in usp_Purchase_Create.
        _paybillNumber = configuration["Mpesa:BusinessShortCode"] ?? string.Empty;
    }

    /// <summary>Buys a policy.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreatePurchaseRequest request)
    {
        var isStaffCaller = CurrentRoleCode is RoleCodes.SuperAdmin or RoleCodes.AgentAdmin or RoleCodes.Agent or RoleCodes.SupportAgent;

        if (isStaffCaller && !CallerHasPermission(PermissionCodes.PurchaseOnBehalf))
        {
            // A real authorization failure, not a business-rule one - 403,
            // not the usual 200/BusinessFailure envelope, to match what
            // [Authorize(Policy=)] would have produced for any other action.
            return Forbid();
        }

        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        // usp_Purchase_Create derives its own AuditLog actor_type/actor_id
        // from whichever of these two is non-null - no separate p_actor_type/
        // p_actor_id params exist on this proc (unlike the Quotes procs).
        long? purchasedByUserId = CurrentRoleCode == RoleCodes.ChannelService ? null : CurrentUserId;
        long? channelServiceAccountId = CurrentRoleCode == RoleCodes.ChannelService ? CurrentUserId : null;

        var result = await _purchaseRepository.CreateAsync(
            request.ProductId, request.ClientId, purchasedByUserId, channelServiceAccountId,
            request.UnderwriterId, request.QuoteOfferId, request.PremiumAmount, request.PeriodId,
            request.StartDate, request.PolicyNumber, request.VehicleId, request.VehicleValue,
            request.Tonnage, request.LicensedToCarry, request.AntiTheft, request.Risk, request.SnapshotAmount);

        if (!result.IsSuccess || result.Data is null)
        {
            _logger.LogWarn($"Purchase create failed for client_id={request.ClientId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        result.Data.PaybillNumber = _paybillNumber;

        _logger.LogInfo($"Purchase created: purchase_id={result.Data.PurchaseId}, policy_number={result.Data.PolicyNumber}, account_number={result.Data.AccountNumber}, client_id={request.ClientId}.");
        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Fetches one purchase, including its Motor snapshot if it has one.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<Purchase>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(long id)
    {
        var result = await _purchaseRepository.GetByIdAsync(id);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        if (!await CallerOwnsClientRecordAsync(result.Data.ClientId))
        {
            return BusinessFailure("Purchase not found.");
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Lists/searches purchases - an Agent sees only purchases they personally executed.</summary>
    // Same scoping shape as ClientsController.GetList: Agent is
    // self-scoped by their own JWT, AgentAdmin/SupportAgent/SuperAdmin see
    // everyone. VIEW_ALL_PURCHASES isn't checked as a policy gate here for
    // the same reason it isn't on ClientsController.GetList - read access
    // for staff roles is broader than the write-permission list.
    // paymentStatus (PENDING/PAID) is separate from status (ACTIVE/EXPIRED/
    // CANCELLED) - pass paymentStatus=PENDING for "payment not yet
    // confirmed" (or just use GetPendingPayment below, same filter fixed in).
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PurchaseListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] long? clientId, [FromQuery] long? productId, [FromQuery] long? underwriterId,
        [FromQuery] string? status, [FromQuery] string? paymentStatus,
        [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo,
        [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        long? purchasedByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _purchaseRepository.GetListAsync(
            clientId, purchasedByUserId, productId, underwriterId, status, paymentStatus, dateFrom, dateTo, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Purchases still awaiting payment confirmation - payment_status is PENDING, not PAID yet.</summary>
    // Thin convenience wrapper over GetList(paymentStatus: "PENDING") - a
    // fixed, discoverable route rather than making every caller remember
    // the query-param spelling. Exists because nothing resolves
    // payment_status automatically yet (no Daraja callback endpoint, no
    // background reconciliation job) - this is how an Agent/back-office
    // staff finds what still needs following up (nudge the customer, check
    // Payments.GetByPurchase for a stuck/failed attempt, or just wait for
    // them to pay via Paybill). Same Agent-self-scoping as GetList.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet("pending-payment")]
    [ProducesResponseType(typeof(ApiResponse<PurchaseListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPendingPayment(
        [FromQuery] long? clientId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        long? purchasedByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _purchaseRepository.GetListAsync(
            clientId, purchasedByUserId, null, null, null, "PENDING", null, null, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetList (pending-payment) returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard stat-card counts (by status and payment_status) - an Agent sees only their own totals, everyone else sees the platform-wide rollup.</summary>
    // Same Agent-self-scoping as GetList/GetPendingPayment above.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<PurchaseDashboardSummary>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary()
    {
        long? purchasedByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _purchaseRepository.GetSummaryAsync(purchasedByUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetSummary returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard widget: today's and this month's purchase count + premium total. Always platform-wide - back-office only, unlike the Agent-inclusive summary above.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("period-totals")]
    [ProducesResponseType(typeof(ApiResponse<PurchasePeriodTotals>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPeriodTotals()
    {
        var result = await _purchaseRepository.GetPeriodTotalsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetPeriodTotals returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard chart: top 10 underwriters by premium written. Always platform-wide, back-office only.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("by-underwriter")]
    [ProducesResponseType(typeof(ApiResponse<List<UnderwriterSalesSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetByUnderwriter()
    {
        var result = await _purchaseRepository.GetByUnderwriterAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetByUnderwriter returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard table: every product's purchase count + premium total. Always platform-wide, back-office only.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("by-product")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductSalesSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetByProduct()
    {
        var result = await _purchaseRepository.GetByProductAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetByProduct returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard chart: exactly 6 months of purchase counts + premium totals, oldest to newest. Always platform-wide, back-office only.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("monthly-trend")]
    [ProducesResponseType(typeof(ApiResponse<List<MonthlyTrendPoint>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMonthlyTrend()
    {
        var result = await _purchaseRepository.GetMonthlyTrendAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetMonthlyTrend returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard chart: top 10 agents by policies sold. Always platform-wide, back-office only.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("top-agents")]
    [ProducesResponseType(typeof(ApiResponse<List<TopAgentSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTopAgents()
    {
        var result = await _purchaseRepository.GetTopAgentsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Purchase_GetTopAgents returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Changes a purchase's status - e.g. cancelling a policy.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpPut("{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateStatus(long id, [FromBody] UpdatePurchaseStatusRequest request)
    {
        var result = await _purchaseRepository.UpdateStatusAsync(id, request.Status, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Purchase status changed: purchase_id={id}, status={request.Status}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>
    /// Completes a fully-paid purchase - the shared completion routine (the
    /// exact code path the background take-over service invokes once a
    /// payment is confirmed, and that a user retry would also call). Marks
    /// certificate_status = GENERATED and returns the "payment received -
    /// your certificate will be emailed to you shortly" confirmation.
    /// </summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize]
    [HttpPost("{id}/complete-cert")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CompleteCert(long id)
    {
        var actorType = CurrentRoleCode switch
        {
            RoleCodes.Client => "CLIENT",
            RoleCodes.ChannelService => "CHANNEL_SERVICE",
            _ => "USER"
        };

        var result = await _purchaseRepository.CompleteCertAsync(id, actorType, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Purchase certificate completed: purchase_id={id}, actor_type={actorType}, actor_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    private bool CallerHasPermission(string permissionCode) => User.FindAll("permission").Any(c => c.Value == permissionCode);

    /// <summary>True if the caller is allowed to act on/see a purchase tied to this client_id - same rule as QuoteRequestsController.</summary>
    private async Task<bool> CallerOwnsClientRecordAsync(long clientId)
    {
        if (CurrentRoleCode != RoleCodes.Client)
        {
            return true;
        }

        var clientResult = await _clientRepository.GetByIdAsync(clientId);
        return clientResult.IsSuccess && clientResult.Data?.UserId == CurrentUserId;
    }
}
