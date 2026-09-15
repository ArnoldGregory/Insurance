namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// An Agent's flat commission percentage - not tied to any product or
/// underwriter. This IS the rate (insert-only history: closing a row and
/// inserting a new one is how a rate change is recorded), not an override
/// of anything - usp_AgentCommissionRate_GetListByAgent's row shape.
/// </summary>
public class AgentCommissionRate
{
    public long RateId { get; set; }
    public long AgentUserId { get; set; }
    public decimal RatePercent { get; set; }
    public DateTime EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public long SetByUserId { get; set; }
    public DateTime CreatedOn { get; set; }
}
