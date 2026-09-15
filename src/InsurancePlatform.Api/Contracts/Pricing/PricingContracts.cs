namespace InsurancePlatform.Api.Contracts.Pricing;

/// <summary>Sets a new active TPO price for one underwriter+vehicle-class+period+capacity combination.</summary>
// CarryCapacity and Tonnage are both optional here for the same reason
// they're both nullable on the table - only one applies, per
// MotorVehicleClass.RequiresTonnage. EffectiveFrom defaults to today
// server-side (usp_TpoPriceMapping_SetPrice) if left null.
public class SetTpoPriceRequest
{
    public long UnderwriterId { get; set; }
    public long VehicleClassId { get; set; }
    public long PeriodId { get; set; }
    public string? CarryCapacity { get; set; }
    public decimal? Tonnage { get; set; }
    public decimal Price { get; set; }
    public DateTime? EffectiveFrom { get; set; }
}

/// <summary>Sets a new active Comprehensive rate formula for one underwriter+vehicle-class.</summary>
// Starts fresh with no factors - AddComprehensiveFactorRequest calls add
// them afterward, one at a time, against the returned formula_id.
public class SetComprehensiveRateRequest
{
    public long UnderwriterId { get; set; }
    public long VehicleClassId { get; set; }
    public decimal BaseRatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public DateTime? EffectiveFrom { get; set; }
}

public class AddComprehensiveFactorRequest
{
    public string FactorType { get; set; } = string.Empty;
    public decimal FactorPercent { get; set; }
}

public class UpsertRateBandRequest
{
    public long? BandId { get; set; }
    public long UnderwriterId { get; set; }
    public decimal ValueMin { get; set; }
    public decimal ValueMax { get; set; }
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public int DisplayOrder { get; set; }
}

public class UpsertBenefitRequest
{
    public long? BenefitId { get; set; }
    public long UnderwriterId { get; set; }
    public string BenefitCode { get; set; } = string.Empty;
    public string BenefitName { get; set; } = string.Empty;
    public decimal DefaultPrice { get; set; }
    public bool IsIncludedInBase { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
}

public class UpsertLiabilityLimitRequest
{
    public long? LiabilityLimitId { get; set; }
    public long UnderwriterId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}
