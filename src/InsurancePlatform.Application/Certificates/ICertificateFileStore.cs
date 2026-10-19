namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Keeps a local copy of the official certificate PDF an underwriter / NTSA
/// hands back as a (usually short-lived, signed) download link. Mirrors
/// BIMADLINE's CertificateDownload.DownloadAndSavePdf: the link is fetched
/// once and the PDF is saved under a deterministic name, so it can still be
/// served after the remote link has expired.
/// </summary>
public interface ICertificateFileStore
{
    /// <summary>
    /// Downloads the PDF at <paramref name="url"/> and saves it for this
    /// purchase/certificate. Returns the saved file name, or null when the
    /// download failed or the response was not a PDF. Never throws.
    /// </summary>
    Task<string?> SaveFromUrlAsync(long purchaseId, string certificateNo, string url, CancellationToken ct = default);

    /// <summary>Opens the saved PDF for reading, or null when it isn't on disk. Caller disposes the stream.</summary>
    Stream? Open(long purchaseId, string certificateNo);

    /// <summary>The file name used for this purchase/certificate (whether or not it exists yet).</summary>
    string GetFileName(long purchaseId, string certificateNo);
}
