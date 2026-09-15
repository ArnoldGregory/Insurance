namespace InsurancePlatform.Domain.Entities;

public class LiabilityLimit
{
    public long LiabilityLimitId { get; set; }
    public long UnderwriterId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}
