namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// Fixed/seeded reference data - not managed via the API. The DMVIC-style
/// motor policy level (e.g. "Type C - Private Car") that both
/// MotorVehicleClasses.PolicyLevelId and UnderwriterPolicyLevelNumber.PolicyLevelId
/// point at.
/// </summary>
public class PolicyLevel
{
    public int PolicyLevelId { get; set; }
    public string Name { get; set; } = string.Empty;
}
