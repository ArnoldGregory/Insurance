namespace InsurancePlatform.Domain.Entities;

/// <summary>One withdrawal request - usp_CommissionWithdrawal_GetListByAgent's row shape.</summary>
public class CommissionWithdrawal
{
    public long WithdrawalId { get; set; }
    public long AgentUserId { get; set; }
    public decimal Amount { get; set; }

    /// <summary>REQUESTED, APPROVED, PAID or REJECTED.</summary>
    public string Status { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
    public long? ProcessedByUserId { get; set; }
    public DateTime? ProcessedOn { get; set; }
}

/// <summary>usp_CommissionWithdrawal_GetPendingList's row shape - the backoffice processing queue, with the agent's name already joined in.</summary>
public class CommissionWithdrawalQueueItem
{
    public long WithdrawalId { get; set; }
    public long AgentUserId { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
}

/// <summary>usp_CommissionWithdrawal_Request's two proc-specific OUT params.</summary>
public class CommissionWithdrawalRequestResult
{
    public long WithdrawalId { get; set; }
    public decimal Amount { get; set; }
}
