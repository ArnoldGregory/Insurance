namespace AmuraWebsite.Services;

public enum SubmissionType
{
    ContactMessage,
    MedicalIndividual,
    MedicalCorporate,
    ProfessionalIndemnity,
    Travel,
    Domestic,
    Motor
}

/// <summary>
/// One submission from any form on the site (Contact, or any of the 5 Get Quote
/// forms). ContactName/Email/Phone are the common fields every form collects;
/// Details holds whatever is specific to that product so this type doesn't need
/// to change every time a product's field list changes.
/// </summary>
public sealed class QuoteSubmission
{
    public string ReferenceNumber { get; set; } = string.Empty;
    public SubmissionType Type { get; set; }
    public DateTimeOffset SubmittedAtUtc { get; set; } = DateTimeOffset.UtcNow;

    public string ContactName { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string? ContactPhone { get; set; }

    public Dictionary<string, string> Details { get; set; } = new();
}
