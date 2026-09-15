using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.AgentCommission + the ledger page wrapper.</summary>
public class AgentCommissionItem
{
    public long CommissionId { get; set; }
    public long PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public decimal RatePercentApplied { get; set; }
    public decimal CoverAmount { get; set; }
    public decimal CommissionAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public long? WithdrawalId { get; set; }
    public DateTime CreatedOn { get; set; }
}

public class AgentCommissionListPage
{
    public long TotalCount { get; set; }
    public List<AgentCommissionItem> Items { get; set; } = new();
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.AgentCommission.RateList entry - the per-agent rate record the Manage screen edits.</summary>
public class AgentCommissionRateItem
{
    public long RateId { get; set; }
    public long AgentUserId { get; set; }
    public decimal RatePercent { get; set; }
    public DateTime EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public long SetByUserId { get; set; }
    public DateTime CreatedOn { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.CommissionWithdrawal.CommissionWithdrawalQueueItem.</summary>
public class CommissionWithdrawalQueueItem
{
    public long WithdrawalId { get; set; }
    public long AgentUserId { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.CommissionWithdrawal.CommissionWithdrawal (agent's own view).</summary>
public class CommissionWithdrawalItem
{
    public long WithdrawalId { get; set; }
    public long AgentUserId { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
    public long? ProcessedByUserId { get; set; }
    public DateTime? ProcessedOn { get; set; }
}

/// <summary>Admin (AA/SP) Manage screen - summary cards + every agent's rate + pending withdrawal queue.</summary>
public class ManageCommissionsViewModel
{
    public AgentCommissionDashboardSummary Summary { get; set; } = new();
    public List<StaffOption> Agents { get; set; } = new();
    public Dictionary<long, List<AgentCommissionRateItem>> RatesByAgent { get; set; } = new();
    public List<CommissionWithdrawalQueueItem> PendingWithdrawals { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    public static readonly string[] WithdrawalStatusOptions = { "APPROVED", "PAID", "REJECTED" };
}

/// <summary>Agent (AG) Mine screen - balance card + ledger + own withdrawals (+ manual withdrawal request).</summary>
public class MyCommissionsViewModel
{
    public decimal Balance { get; set; }
    public AgentCommissionListPage Ledger { get; set; } = new();
    public List<CommissionWithdrawalItem> Withdrawals { get; set; } = new();

    public bool CanRequestWithdrawal { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Modal binding model - POST /api/agent-commissions/rate (SetAgentCommissionRateRequest).</summary>
public class SetCommissionRateFormModel
{
    public long AgentUserId { get; set; }

    [Range(0, 100, ErrorMessage = "Rate must be between 0 and 100.")]
    public decimal RatePercent { get; set; }

    public DateTime? EffectiveFrom { get; set; }
}

/// <summary>Modal binding model - PUT /api/agent-commissions/withdrawals/{id}/status (UpdateCommissionWithdrawalStatusRequest).</summary>
public class WithdrawalStatusFormModel
{
    public long WithdrawalId { get; set; }
    public string Status { get; set; } = string.Empty;
}