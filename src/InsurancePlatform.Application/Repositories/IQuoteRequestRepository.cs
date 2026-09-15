using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

// One Create method per product detail table, mirroring the SQL file's own
// "one Create proc per type" design - each type has genuinely different
// required fields, so a single generic CreateAsync(dictionary) would just
// push the type-specific validation into the caller instead of removing it.
public interface IQuoteRequestRepository
{
    // Channel is not a parameter - Medical Individual requests are WEBSITE-only, hardcoded in the proc.
    Task<StoredProcResult<QuoteRequestCreateResult?>> CreateMedicalIndividualAsync(
        long? clientId, long? requestedByUserId,
        string idNo, string firstName, string lastName, string? otherNames, string email, string mobileNumber,
        decimal inpatientLimit, bool hasOutpatient, decimal? outpatientLimit,
        bool hasDental, decimal? dentalLimit, bool hasMaternity,
        string? familyMembersJson, string actorType, long actorId);

    Task<StoredProcResult<QuoteRequestCreateResult?>> CreateMedicalCorporateAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string companyName, string phone,
        string email, string actorType, long actorId);

    Task<StoredProcResult<QuoteRequestCreateResult?>> CreateProfessionalIndemnityAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string clientOrCompanyName, string phone,
        string email, string profession, string actorType, long actorId);

    Task<StoredProcResult<QuoteRequestCreateResult?>> CreateTravelAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string email, string clientName, DateTime dob,
        string? kraPin, string destination, DateTime travelDateFrom, DateTime travelDateTo,
        bool? travellingWithFamily, string tripType, string actorType, long actorId);

    Task<StoredProcResult<QuoteRequestCreateResult?>> CreateDomesticAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string email, string? detailsJson, string actorType, long actorId);

    Task<StoredProcResult<QuoteRequest?>> GetByIdAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestMedicalIndividualDetail?>> GetMedicalIndividualDetailAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestMedicalCorporateDetail?>> GetMedicalCorporateDetailAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestProfessionalIndemnityDetail?>> GetProfessionalIndemnityDetailAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestTravelDetail?>> GetTravelDetailAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestDomesticDetail?>> GetDomesticDetailAsync(long quoteRequestId);

    Task<StoredProcResult<QuoteRequestListPage>> GetListAsync(
        string? status, long? assignedBackofficeUserId, long? productId, int pageNumber, int pageSize);

    /// <summary>Wraps usp_QuoteRequest_GetSummary - the per-product pending/in-progress/total counts for the list screen's header.</summary>
    Task<StoredProcResult<List<QuoteRequestProductSummary>>> GetSummaryAsync();

    Task<StoredProcResult> AssignBackofficeAsync(long quoteRequestId, long assignedBackofficeUserId, long actorId);

    Task<StoredProcResult> ExpireAsync(long quoteRequestId, long actorId);
}
