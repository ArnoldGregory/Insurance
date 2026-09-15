namespace InsurancePlatform.AdminPortal.Models;

public class ComprehensiveSettingsViewModel
{
    public long? FilterUnderwriterId { get; set; }
    public List<RateBandAdminItem> RateBands { get; set; } = new();
    public List<BenefitAdminItem> Benefits { get; set; } = new();
    public List<LiabilityLimitAdminItem> LiabilityLimits { get; set; } = new();
    public List<UnderwriterOption> Underwriters { get; set; } = new();
}

public class RateBandAdminItem
{
    public long BandId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal ValueMin { get; set; }
    public decimal ValueMax { get; set; }
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public DateTime? EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; }
}

public class BenefitAdminItem
{
    public long BenefitId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public string BenefitCode { get; set; } = string.Empty;
    public string BenefitName { get; set; } = string.Empty;
    public decimal DefaultPrice { get; set; }
    public bool IsIncludedInBase { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
}

public class LiabilityLimitAdminItem
{
    public long LiabilityLimitId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}

public class RateBandFormModel
{
    public long? BandId { get; set; }
    public long UnderwriterId { get; set; }
    public decimal ValueMin { get; set; }
    public decimal ValueMax { get; set; }
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public int DisplayOrder { get; set; }
}

public class BenefitFormModel
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

public class LiabilityLimitFormModel
{
    public long? LiabilityLimitId { get; set; }
    public long UnderwriterId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.TpoPriceMapping - one row of the TPO price-mapping admin screen.</summary>
public class TpoPriceMappingItem
{
    public long TpoPriceId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public long VehicleClassId { get; set; }
    public string VehicleClassName { get; set; } = string.Empty;
    public long PeriodId { get; set; }
    public string PeriodName { get; set; } = string.Empty;
    public string? CarryCapacity { get; set; }
    public decimal? Tonnage { get; set; }
    public decimal Price { get; set; }
    public DateTime? EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; }
}

/// <summary>Wrapper for GET /api/pricing/tpo/list (TpoPriceMappingListPage).</summary>
public class TpoPriceMappingListPage
{
    public long TotalCount { get; set; }
    public List<TpoPriceMappingItem> Items { get; set; } = new();
}

/// <summary>Binding model for the TPO Price Mapping screen (filters + tabs not needed - single table + add/edit modal).</summary>
public class TpoPriceMappingViewModel
{
    public TpoPriceMappingListPage Mappings { get; set; } = new();
    public List<UnderwriterOption> Underwriters { get; set; } = new();
    public List<MotorVehicleClassItem> VehicleClasses { get; set; } = new();
    public List<PeriodItem> Periods { get; set; } = new();

    public long? FilterUnderwriterId { get; set; }
    public long? FilterVehicleClassId { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Modal binding - POST /api/pricing/tpo (SetTpoPriceRequest).</summary>
public class SetTpoPriceFormModel
{
    public long UnderwriterId { get; set; }
    public long VehicleClassId { get; set; }
    public long PeriodId { get; set; }

    public string? CarryCapacity { get; set; }
    public decimal? Tonnage { get; set; }

    public decimal Price { get; set; }
    public DateTime? EffectiveFrom { get; set; }
}

