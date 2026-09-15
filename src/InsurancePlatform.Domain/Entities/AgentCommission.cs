namespace InsurancePlatform.Domain.Entities;

/// <summary>One agent's earnings on one purchase - usp_AgentCommission_GetListByAgent's row shape.</summary>
public class AgentCommission
{
    public long CommissionId { get; set; }
    public long PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public decimal RatePercentApplied { get; set; }
    public decimal CoverAmount { get; set; }
    public decimal CommissionAmount { get; set; }

    /// <summary>ACCRUED or WITHDRAWN.</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>Set once this commission is reserved by a withdrawal request - null while freely available.</summary>
    public long? WithdrawalId { get; set; }
    public DateTime CreatedOn { get; set; }
}

/// <summary>Paginated wrapper for usp_AgentCommission_GetListByAgent - same shape as ClientListPage.</summary>
public class AgentCommissionListPage
{
    public long TotalCount { get; set; }
    public List<AgentCommission> Items { get; set; } = new();
}

/// <summary>usp_AgentCommission_GetSummary's single-row shape - platform-wide commission totals for the
/// SuperAdmin/AgentAdmin/SupportAgent dashboards (not any one agent's own numbers - that's still
/// usp_AgentCommission_GetAvailableBalance's single decimal, unchanged).</summary>
public class AgentCommissionDashboardSummary
{
    public decimal TotalAccrued { get; set; }
    public decimal TotalWithdrawn { get; set; }
    public decimal AvailableBalance { get; set; }
    public long PendingWithdrawalCount { get; set; }
    public decimal PendingWithdrawalAmount { get; set; }
}
