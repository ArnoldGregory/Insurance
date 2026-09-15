using InsurancePlatform.Api.Contracts.Commissions;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>An agent's earnings ledger and the withdrawal request/approve/pay/reject flow.</summary>
// "Me" endpoints are self-service (Agent role, always scoped to the
// caller's own CurrentUserId - never a body/query-supplied agent id, so
// one Agent can never read another's earnings). Accrue is the AgentAdmin
// backfill action; UpdateWithdrawalStatus/GetPendingWithdrawals are the
// AgentAdmin/SupportAgent backoffice processing side, per this SQL file's
// own comments on usp_AgentCommission_Accrue and
// usp_CommissionWithdrawal_UpdateStatus.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AgentCommissionsController : BaseApiController
{
    private readonly IAgentCommissionRepository _agentCommissionRepository;
    private readonly IAgentCommissionRateRepository _agentCommissionRateRepository;
    private readonly ILoggerManager _logger;

    private const string BackofficeRoles = $"{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}";

    public AgentCommissionsController(
        IAgentCommissionRepository agentCommissionRepository,
        IAgentCommissionRateRepository agentCommissionRateRepository,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _agentCommissionRepository = agentCommissionRepository;
        _agentCommissionRateRepository = agentCommissionRateRepository;
        _logger = logger;
    }

    /// <summary>Sets an agent's flat commission rate - one percentage applied to every purchase they make, regardless of product or underwriter.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("rate")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetRate([FromBody] SetAgentCommissionRateRequest request)
    {
        var result = await _agentCommissionRateRepository.SetAsync(
            request.AgentUserId, request.RatePercent, request.EffectiveFrom, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Agent commission rate set failed for agent_user_id={request.AgentUserId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Agent commission rate set: rate_id={result.Data}, agent_user_id={request.AgentUserId}, by user_id={CurrentUserId}.");
        return Success(new { RateId = result.Data }, result.ResultMessage);
    }

    /// <summary>Lists an agent's rate history, current and superseded - an Agent can only see their own.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("rate/by-agent/{agentUserId}")]
    [ProducesResponseType(typeof(ApiResponse<List<AgentCommissionRate>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRateListByAgent(long agentUserId)
    {
        if (CurrentRoleCode == RoleCodes.Agent && agentUserId != CurrentUserId)
        {
            return BusinessFailure("Not found.");
        }

        var result = await _agentCommissionRateRepository.GetListByAgentAsync(agentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_AgentCommissionRate_GetListByAgent returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Manual/backfill commission accrual for a purchase that didn't get one automatically.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("accrue")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Accrue([FromBody] AccrueAgentCommissionRequest request)
    {
        var result = await _agentCommissionRepository.AccrueAsync(request.PurchaseId, request.AgentUserId, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Commission accrue failed for purchase_id={request.PurchaseId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Commission accrued: commission_id={result.Data}, purchase_id={request.PurchaseId}, agent_user_id={request.AgentUserId}, by user_id={CurrentUserId}.");
        return Success(new { CommissionId = result.Data }, result.ResultMessage);
    }

    /// <summary>The caller's own paginated earnings ledger.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = RoleCodes.Agent)]
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<AgentCommissionListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyLedger([FromQuery] string? status, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _agentCommissionRepository.GetListByAgentAsync(CurrentUserId, status, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_AgentCommission_GetListByAgent returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>The caller's own available balance - ACCRUED commissions not already reserved by a pending/paid withdrawal.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = RoleCodes.Agent)]
    [HttpGet("me/balance")]
    [ProducesResponseType(typeof(ApiResponse<decimal>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBalance()
    {
        var result = await _agentCommissionRepository.GetAvailableBalanceAsync(CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_AgentCommission_GetAvailableBalance returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Requests a payout of the caller's full available balance - no partial-amount withdrawals in this version.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.WithdrawCommission)]
    [HttpPost("withdrawals")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> RequestWithdrawal()
    {
        var result = await _agentCommissionRepository.RequestWithdrawalAsync(CurrentUserId);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Commission withdrawal requested: withdrawal_id={result.Data.WithdrawalId}, amount={result.Data.Amount}, agent_user_id={CurrentUserId}.");
        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Approves, pays, or rejects a withdrawal request.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPut("withdrawals/{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateWithdrawalStatus(long id, [FromBody] UpdateCommissionWithdrawalStatusRequest request)
    {
        var result = await _agentCommissionRepository.UpdateWithdrawalStatusAsync(id, request.Status, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Commission withdrawal status changed: withdrawal_id={id}, status={request.Status}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>The caller's own withdrawal request history.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = RoleCodes.Agent)]
    [HttpGet("me/withdrawals")]
    [ProducesResponseType(typeof(ApiResponse<List<CommissionWithdrawal>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyWithdrawals()
    {
        var result = await _agentCommissionRepository.GetWithdrawalListByAgentAsync(CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_CommissionWithdrawal_GetListByAgent returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>The backoffice processing queue - REQUESTED/APPROVED withdrawals across every agent.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpGet("withdrawals/pending")]
    [ProducesResponseType(typeof(ApiResponse<List<CommissionWithdrawalQueueItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPendingWithdrawals()
    {
        var result = await _agentCommissionRepository.GetPendingWithdrawalsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_CommissionWithdrawal_GetPendingList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Platform-wide commission totals for the SuperAdmin/AgentAdmin/SupportAgent dashboards - not any one agent's own numbers (that's GetMyBalance above).</summary>
    // SuperAdmin included here even though it's not in BackofficeRoles
    // (SetRate/Accrue gate on the ManagePricing/WithdrawCommission policies
    // instead, which SA already holds) - same "SA sees every dashboard
    // widget" reasoning as QuoteBackoffice's own SA,AA,SP role list.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{BackofficeRoles}")]
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<AgentCommissionDashboardSummary>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary()
    {
        var result = await _agentCommissionRepository.GetSummaryAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_AgentCommission_GetSummary returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }
}
