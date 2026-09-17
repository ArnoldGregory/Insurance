namespace InsurancePlatform.Application.Certificates;

/// <summary>Result of a best-effort NTSA/D-MVIC certificate issuance attempt.</summary>
public class DmvicIssueResult
{
    public bool Issued { get; set; }

    /// <summary>NTSA certificate number (actualCNo) when the issuance succeeded.</summary>
    public string? CertificateNo { get; set; }

    public string? TransactionNo { get; set; }

    /// <summary>Human-readable outcome for logging - NOT for the client (failure always falls back to the internal certificate).</summary>
    public string Message { get; set; } = string.Empty;
}