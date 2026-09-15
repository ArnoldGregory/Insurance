using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

// Covers both AgentCommissions (per-purchase earnings) and
// CommissionWithdrawals (the request/approve/pay/reject flow on top of
// those earnings) - grouped together because a withdrawal only ever
// operates on this same agent's AgentCommissions rows (reserving/releasing
// them).
public interface IAgentCommissionRepository
{
    /// <summary>Manual/backfill accrual for a purchase that didn't get one automatically (no rate configured yet at purchase time).</summary>
    Task<StoredProcResult<long?>> AccrueAsync(long purchaseId, long agentUserId, long actorId);

    Task<StoredProcResult<AgentCommissionListPage>> GetListByAgentAsync(long agentUserId, string? status, int pageNumber, int pageSize);

    Task<StoredProcResult<decimal>> GetAvailableBalanceAsync(long agentUserId);

    /// <summary>Withdraws the agent's full available balance - no partial-amount withdrawals in this version.</summary>
    Task<StoredProcResult<CommissionWithdrawalRequestResult?>> RequestWithdrawalAsync(long agentUserId);

    Task<StoredProcResult> UpdateWithdrawalStatusAsync(long withdrawalId, string status, long actorId);

    Task<StoredProcResult<List<CommissionWithdrawal>>> GetWithdrawalListByAgentAsync(long agentUserId);

    /// <summary>The backoffice processing queue - REQUESTED/APPROVED withdrawals across every agent.</summary>
    Task<StoredProcResult<List<CommissionWithdrawalQueueItem>>> GetPendingWithdrawalsAsync();

    /// <summary>
    /// Wraps usp_AgentCommission_GetSummary - platform-wide commission
    /// totals for the SuperAdmin/AgentAdmin/SupportAgent dashboards. Not
    /// scoped to one agent - that's still GetAvailableBalanceAsync above.
    /// </summary>
    Task<StoredProcResult<AgentCommissionDashboardSummary>> GetSummaryAsync();
}
