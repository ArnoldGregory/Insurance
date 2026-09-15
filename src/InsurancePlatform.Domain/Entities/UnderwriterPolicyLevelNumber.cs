namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One row from usp_UnderwriterPolicyLevelNumber_GetList - the ONE fixed,
/// reused policy_number an underwriter stamps on every certificate sold
/// at a given policy_level. Only meaningful when the underwriter's own
/// PolicyType is "FIXED" - PolicyType is included here (denormalized from
/// Underwriters) so a caller doesn't need a second lookup to know whether
/// this number is actually in play for a sale. policy_level_id is the
/// underwriter's own DMVIC-style level categorization, kept as an opaque
/// integer - not (yet) mapped to MotorVehicleClasses.PolicyLevelId.
/// </summary>
public class UnderwriterPolicyLevelNumber
{
    public long Id { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public string PolicyType { get; set; } = string.Empty;
    public int PolicyLevelId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}
