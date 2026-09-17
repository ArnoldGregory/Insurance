namespace AmuraWebsite.Services;

public interface IInsurancePlatformClient
{
    bool IsConfigured { get; }

    Task<PlatformSubmissionResult?> SubmitMedicalIndividualAsync(
        string clientName, DateTime clientDob, string idNo, string email, string phone,
        IReadOnlyList<(string Relationship, string FullName, DateTime DateOfBirth)> familyMembers,
        CancellationToken ct = default);

    Task<PlatformSubmissionResult?> SubmitMedicalCorporateAsync(
        string companyName, string phone, string email,
        string idNo,
        CancellationToken ct = default);

    Task<PlatformSubmissionResult?> SubmitProfessionalIndemnityAsync(
        string clientOrCompanyName, string phone, string email, string profession,
        string idNo,
        CancellationToken ct = default);

    Task<PlatformSubmissionResult?> SubmitTravelAsync(
        string clientName, DateTime dob, string? kraPin, string destination,
        DateTime travelDateFrom, DateTime travelDateTo, bool travellingWithFamily, string tripType,
        string idNo, string email,
        CancellationToken ct = default);

    Task<PlatformSubmissionResult?> SubmitDomesticAsync(
        string detailsJson,
        string idNo,
        string email,
        CancellationToken ct = default);
}