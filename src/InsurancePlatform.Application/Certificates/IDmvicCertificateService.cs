namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Best-effort NTSA/D-MVIC official motor certificate issuance for a
/// completed purchase. Failures are always logged, never thrown to the
/// purchase flow - the purchase keeps its internally-generated HTML
/// certificate either way.
/// </summary>
public interface IDmvicCertificateService
{
    Task<DmvicIssueResult> IssueForPurchaseAsync(long purchaseId);

    /// <summary>
    /// The official certificate PDF for an issued NTSA certificate - served
    /// from the local copy, re-fetched from NTSA when missing. Null when no
    /// PDF can be obtained. Caller disposes the stream.
    /// </summary>
    Task<Stream?> OpenCertificatePdfAsync(long purchaseId, string certificateNo);
}