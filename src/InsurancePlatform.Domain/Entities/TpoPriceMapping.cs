namespace InsurancePlatform.Domain.Entities;

/// <summary>usp_TpoPriceMapping_GetList's row shape - one row per priced combination.</summary>
public class TpoPriceMapping
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
    public DateTime EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public bool IsActive { get; set; }
}

/// <summary>Paginated wrapper for usp_TpoPriceMapping_GetList - same shape as ClientListPage.</summary>
public class TpoPriceMappingListPage
{
    public long TotalCount { get; set; }
    public List<TpoPriceMapping> Items { get; set; } = new();
}

/// <summary>
/// usp_TpoPriceMapping_GetOptions's row shape - one row per underwriter
/// currently pricing the requested vehicle_class+period+capacity/tonnage
/// combination, cheapest first. The caller compares these and picks which
/// underwriter (UnderwriterId) to buy from.
/// </summary>
public class TpoPriceOption
{
    public long TpoPriceId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal Price { get; set; }
}
