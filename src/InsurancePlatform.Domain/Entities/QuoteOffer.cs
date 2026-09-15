namespace InsurancePlatform.Domain.Entities;

/// <summary>One priced option a back-office user uploaded against a QuoteRequest, from one underwriter.</summary>
public class QuoteOffer
{
    public long QuoteOfferId { get; set; }
    public long QuoteRequestId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public string? DocumentPath { get; set; }
    public long UploadedByUserId { get; set; }
    public DateTime UploadedOn { get; set; }
    public string Status { get; set; } = string.Empty;
}
