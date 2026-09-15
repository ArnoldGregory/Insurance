namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// Fixed/seeded reference data - not managed via the API. usp_Period_GetList
/// doesn't select duration_days, since the API never needs to compute an
/// end_date itself - usp_Purchase_Create does that server-side from the
/// period_id alone.
/// </summary>
public class Period
{
    public long PeriodId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? DmvicCode { get; set; }
}
