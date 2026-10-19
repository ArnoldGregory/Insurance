using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

/// <summary>
/// Persistence for non-DMVIC insurer certificate requests (DirectLine,
/// AMACO, Definite) - see underwriter_integrations_migration.sql.
/// </summary>
public interface IUnderwriterCertificateRepository
{
    /// <summary>usp_UnderwriterCert_GetPurchaseData.</summary>
    Task<StoredProcResult<UnderwriterCertPurchaseData?>> GetPurchaseDataAsync(long purchaseId);

    /// <summary>usp_UnderwriterCert_CreateRequest - Duplicate (3) when a certificate or an open request already exists.</summary>
    Task<StoredProcResult<long?>> CreateRequestAsync(
        long purchaseId, string integration, string externalRef, string status, string? requestPayload);

    /// <summary>usp_UnderwriterCert_UpdateRequest - null arguments leave the stored value untouched.</summary>
    Task<StoredProcResult> UpdateRequestAsync(
        long requestId, string? status, string? responsePayload = null, string? callbackPayload = null,
        string? certNo = null, string? policyNo = null, string? certUrl = null, string? errorMessage = null);

    /// <summary>usp_UnderwriterCert_FindForCallback - by external reference, falling back to policy number.</summary>
    Task<StoredProcResult<UnderwriterCertRequest?>> FindForCallbackAsync(
        string integration, string? externalRef, string? policyNumber);
}
