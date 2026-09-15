namespace InsurancePlatform.Domain.Entities;

/// <summary>Fixed/seeded reference data - not managed via the API.</summary>
public class MotorCategory
{
    public long MotorCategoryId { get; set; }
    public long ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
}
