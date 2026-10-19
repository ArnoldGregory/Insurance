namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Picks the right certificate path for a paid purchase's underwriter and
/// handles the insurers' certificate callbacks:
///   * DirectLine          -> SCAPI DIRECTLINE request, certificate arrives by callback
///   * AMACO / Definite    -> recorded, certificate arrives by callback
///   * everyone else       -> NTSA/DMVIC (IDmvicCertificateService), unchanged
/// Routing comes from UnderwriterIntegrationOptions. Best-effort like DMVIC:
/// failures are returned/logged, never thrown into the purchase flow.
/// </summary>
public interface IUnderwriterCertificateService
{
    Task<DmvicIssueResult> IssueForPurchaseAsync(long purchaseId);

    /// <summary>
    /// Records an insurer's certificate callback against the matching request
    /// (by our external reference, falling back to policy number), saves the
    /// certificate on the purchase and keeps a copy of the PDF.
    /// </summary>
    Task<UnderwriterCallbackResult> CompleteFromCallbackAsync(UnderwriterCallback callback);
}

/// <summary>Normalised insurer callback - each controller action maps its insurer's JSON into this.</summary>
public class UnderwriterCallback
{
    /// <summary>DIRECTLINE | AMACO | DEFINITE.</summary>
    public required string Integration { get; init; }
    public string? ExternalRef { get; init; }
    public string? PolicyNumber { get; init; }
    public bool Success { get; init; }
    public string? CertificateNo { get; init; }
    public string? CertificateUrl { get; init; }
    public string? ErrorMessage { get; init; }
    public required string RawPayload { get; init; }
}

public class UnderwriterCallbackResult
{
    public bool Accepted { get; init; }
    public long? PurchaseId { get; init; }
    public string Message { get; init; } = string.Empty;
}

/// <summary>Integration codes stored in UnderwriterCertificateRequests.integration.</summary>
public static class UnderwriterIntegrations
{
    public const string DirectLine = "DIRECTLINE";
    public const string Amaco = "AMACO";
    public const string Definite = "DEFINITE";
}
