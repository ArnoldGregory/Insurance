namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One structured add-on/rider line attached to a quote offer (e.g. "RSA",
/// "Anti-theft", "Courtesy car"). Stored as a replace-able set per offer;
/// see usp_QuoteOfferRider_Replace.
/// </summary>
public class QuoteOfferRider
{
    public long RiderId { get; set; }
    public long QuoteOfferId { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>Optional premium impact; null when free/included.</summary>
    public decimal? Amount { get; set; }

    /// <summary>Optional human note/description.</summary>
    public string? Note { get; set; }

    public DateTime CreatedOn { get; set; }
}