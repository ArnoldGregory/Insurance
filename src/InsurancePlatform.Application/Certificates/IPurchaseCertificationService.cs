using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Shared certificate-completion orchestration: usp_Purchase_CompleteCert
/// then best-effort NTSA/D-MVIC issuance (see
/// PurchaseCertificationService for the fallback semantics). Every
/// certificate trigger - M-Pesa callback, retry button, background worker -
/// routes through this so the official-certificate step stays in one place.
/// </summary>
public interface IPurchaseCertificationService
{
    Task<StoredProcResult> CompleteAndIssueAsync(long purchaseId, string actorType, long actorId);
}