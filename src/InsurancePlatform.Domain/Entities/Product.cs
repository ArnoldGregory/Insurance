namespace InsurancePlatform.Domain.Entities;

public class Product
{
    public long ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string PricingMethod { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
