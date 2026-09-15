namespace InsurancePlatform.Domain.Entities;

/// <summary>Row returned by usp_ComprehensiveRateBand_GetOptions - one per underwriter that covers the given vehicle value.</summary>
public class ComprehensiveRateBandOption
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public decimal ValueMin { get; set; }
    public decimal ValueMax { get; set; }
    public decimal BasePremium { get; set; }
    public decimal PvtAmount { get; set; }
    public decimal TotalPremium { get; set; }
}

/// <summary>Row returned by usp_ComprehensiveBenefit_GetList - one optional benefit for an underwriter.</summary>
public class ComprehensiveBenefitItem
{
    public long BenefitId { get; set; }
    public string BenefitCode { get; set; } = string.Empty;
    public string BenefitName { get; set; } = string.Empty;
    public decimal DefaultPrice { get; set; }
    public bool IsIncludedInBase { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
}

public class LiabilityLimitItem
{
    public long LiabilityLimitId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
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
    public DateTime EffectiveFrom { get; set; }
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

/// <summary>Wrapper combining a rate band option with its benefits list - the full compare response.</summary>
public class ComprehensiveCompareResult
{
    public List<ComprehensiveRateBandOption> Options { get; set; } = new();
    public Dictionary<long, List<ComprehensiveBenefitItem>> BenefitsByUnderwriter { get; set; } = new();
    public Dictionary<long, List<LiabilityLimitItem>> LiabilityLimitsByUnderwriter { get; set; } = new();
}
