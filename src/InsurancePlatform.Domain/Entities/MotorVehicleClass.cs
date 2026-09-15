namespace InsurancePlatform.Domain.Entities;

/// <summary>Fixed/seeded reference data - not managed via the API.</summary>
// RequiresTonnage tells the caller which of TpoPriceMapping's two optional
// fields (carry_capacity vs tonnage) applies to this class - PSV-style
// classes carry passengers (capacity), Commercial classes carry weight
// (tonnage). Never both.
public class MotorVehicleClass
{
    public long VehicleClassId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool RequiresTonnage { get; set; }

    /// <summary>Which of the underwriters' DMVIC-style policy levels this class falls under - nullable, not yet populated for every class.</summary>
    public int? PolicyLevelId { get; set; }
}
