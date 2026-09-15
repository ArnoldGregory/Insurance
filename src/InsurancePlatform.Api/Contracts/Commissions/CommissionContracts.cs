namespace InsurancePlatform.Api.Contracts.Commissions;

/// <summary>Sets an Agent's flat commission rate - one percentage applied to every purchase they make, regardless of product or underwriter.</summary>
public class SetAgentCommissionRateRequest
{
    public long AgentUserId { get; set; }
    public decimal RatePercent { get; set; }
    public DateTime? EffectiveFrom { get; set; }
}

/// <summary>Manual/backfill accrual - for a purchase that didn't get a commission automatically because no rate was configured at purchase time.</summary>
public class AccrueAgentCommissionRequest
{
    public long PurchaseId { get; set; }
    public long AgentUserId { get; set; }
}

public class UpdateCommissionWithdrawalStatusRequest
{
    /// <summary>APPROVED, PAID or REJECTED.</summary>
    public string Status { get; set; } = string.Empty;
}
