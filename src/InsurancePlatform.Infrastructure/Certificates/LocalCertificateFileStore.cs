using System.Text.RegularExpressions;
using InsurancePlatform.Application.Certificates;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Infrastructure.Certificates;

/// <summary>
/// Local-disk ICertificateFileStore. Files land in CertificateStorage:Root
/// (falls back to "&lt;app folder&gt;/certificates") as
/// "{purchaseId}_{certificateNo}.pdf" - deterministic, so no extra DB column
/// is needed to find the file again. Only http(s) links are fetched, the
/// body must start with the PDF signature, and size is capped.
/// </summary>
public class LocalCertificateFileStore : ICertificateFileStore
{
    private const long MaxFileSizeBytes = 15 * 1024 * 1024;
    private static readonly Regex UnsafeChars = new("[^A-Za-z0-9_-]", RegexOptions.Compiled);

    private readonly HttpClient _httpClient;
    private readonly ILoggerManager _logger;
    private readonly string _root;

    public LocalCertificateFileStore(HttpClient httpClient, IConfiguration configuration, ILoggerManager logger)
    {
        _httpClient = httpClient;
        _logger = logger;

        var configured = configuration["CertificateStorage:Root"];
        _root = string.IsNullOrWhiteSpace(configured)
            ? Path.Combine(AppContext.BaseDirectory, "certificates")
            : configured;
    }

    public string GetFileName(long purchaseId, string certificateNo)
    {
        var safeCert = UnsafeChars.Replace(certificateNo ?? string.Empty, string.Empty);
        return $"{purchaseId}_{safeCert}.pdf";
    }

    public async Task<string?> SaveFromUrlAsync(long purchaseId, string certificateNo, string url, CancellationToken ct = default)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) ||
            (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
        {
            _logger.LogWarn($"Certificate PDF purchase_id={purchaseId}: '{url}' is not an http(s) link - not downloaded.");
            return null;
        }

        try
        {
            using var response = await _httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarn($"Certificate PDF purchase_id={purchaseId}: download returned {(int)response.StatusCode}.");
                return null;
            }

            if (response.Content.Headers.ContentLength is long length && length > MaxFileSizeBytes)
            {
                _logger.LogWarn($"Certificate PDF purchase_id={purchaseId}: file too large ({length} bytes).");
                return null;
            }

            var bytes = await response.Content.ReadAsByteArrayAsync(ct);
            if (bytes.Length == 0 || bytes.Length > MaxFileSizeBytes || !IsPdf(bytes))
            {
                _logger.LogWarn($"Certificate PDF purchase_id={purchaseId}: response was not a PDF ({bytes.Length} bytes).");
                return null;
            }

            Directory.CreateDirectory(_root);
            var fileName = GetFileName(purchaseId, certificateNo);
            var fullPath = Path.Combine(_root, fileName);
            var tempPath = fullPath + ".tmp";

            await File.WriteAllBytesAsync(tempPath, bytes, ct);
            File.Move(tempPath, fullPath, overwrite: true);

            _logger.LogInfo($"Certificate PDF purchase_id={purchaseId}: saved {fileName} ({bytes.Length} bytes).");
            return fileName;
        }
        catch (Exception ex)
        {
            _logger.LogError($"Certificate PDF purchase_id={purchaseId}: download failed.", ex);
            return null;
        }
    }

    // "%PDF" file signature.
    private static bool IsPdf(byte[] bytes) =>
        bytes.Length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;

    public Stream? Open(long purchaseId, string certificateNo)
    {
        var fullPath = Path.Combine(_root, GetFileName(purchaseId, certificateNo));
        return File.Exists(fullPath)
            ? new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read)
            : null;
    }
}
