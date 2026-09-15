namespace InsurancePlatform.Api.Services;

/// <summary>
/// Local-disk (shared-folder) implementation of IQuoteOfferDocumentStorage -
/// files land in ONE configurable root folder (QuoteOffersStorage:Root in
/// appsettings) instead of being tied to this project's wwwroot. That root
/// is environment-specific:
///   - Ubuntu server: /home/insurancePlatform/requestOffers
///   - Windows dev:   C:\InsurancePlatformData\requestOffers
/// so locally and on the server every upload ends up in the same logical
/// place, and the DB only ever stores the portable relative key
/// ("requestOffers/{guid}.ext") - never an absolute OS path.
///
/// Because the files no longer live under wwwroot, static-file middleware
/// does NOT serve them anymore. They're streamed back out through the
/// authenticated GET /api/quoterequests/{id}/offers/{offerId}/document
/// endpoint (and proxied to browsers by AdminPortal's DownloadOffer action),
/// which also fixes the old "unauthenticated static serving" trade-off.
/// </summary>
public class LocalQuoteOfferDocumentStorage : IQuoteOfferDocumentStorage
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".jpg", ".jpeg", ".png", ".doc", ".docx"
    };

    private const long MaxFileSizeBytes = 10 * 1024 * 1024; // 10 MB - plenty for a scanned underwriter quote.

    /// <summary>Relative prefix stored in QuoteOffers.document_path for every file this class saves.</summary>
    public const string StorageKeyPrefix = "requestOffers";

    private readonly string _root;

    public LocalQuoteOfferDocumentStorage(IConfiguration configuration, IWebHostEnvironment env)
    {
        var configured = configuration["QuoteOffersStorage:Root"];

        // Unset config falls back to the original wwwroot location so the API
        // still boots (and can read pre-migration files) on a machine that
        // hasn't picked up the new appsettings yet.
        _root = string.IsNullOrWhiteSpace(configured)? Path.Combine(env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot"), "uploads", "quote-offers"): configured;

        Directory.CreateDirectory(_root);
    }

    public async Task<string> SaveAsync(IFormFile file)
    {
        var extension = Path.GetExtension(file.FileName);

        if (string.IsNullOrEmpty(extension) || !AllowedExtensions.Contains(extension))
        {
            throw new InvalidOperationException(
                $"Unsupported file type '{extension}'. Allowed: {string.Join(", ", AllowedExtensions)}.");
        }

        if (file.Length <= 0)
        {
            throw new InvalidOperationException("The uploaded file is empty.");
        }

        if (file.Length > MaxFileSizeBytes)
        {
            throw new InvalidOperationException("File is too large - maximum size is 10 MB.");
        }

        // GUID filename, not the original one - sidesteps needing to
        // sanitize/deduplicate user-supplied filenames entirely, and the
        // original name (which the underwriter/back-office person doesn't
        // actually need back) never had to be preserved anywhere.
        var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var fullPath = Path.Combine(_root, fileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return $"{StorageKeyPrefix}/{fileName}";
    }

    public Task<Stream?> OpenAsync(string? storagePath)
    {
        var fullPath = ResolvePhysicalPath(storagePath);

        if (fullPath is null || !System.IO.File.Exists(fullPath))
        {
            return Task.FromResult<Stream?>(null);
        }

        Stream stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return Task.FromResult<Stream?>(stream);
    }

    public string? GetFileName(string? storagePath)
    {
        var fullPath = ResolvePhysicalPath(storagePath);
        return fullPath is null ? null : Path.GetFileName(fullPath);
    }

    /// <summary>
    /// Turns a stored document_path into a real OS path under the shared
    /// root - accepts both the current "requestOffers/{file}" keys and bare
    /// filenames, and safely ignores anything trying to escape the root
    /// (absolute paths or "../" traversal never resolve outside it).
    /// </summary>
    private string? ResolvePhysicalPath(string? storagePath)
    {
        if (string.IsNullOrWhiteSpace(storagePath))
        {
            return null;
        }

        // Strip any prefix up to the last slash - handles "requestOffers/x.pdf",
        // "/uploads/quote-offers/x.pdf" (legacy rows) and bare "x.pdf" alike.
        var fileName = Path.GetFileName(storagePath.Replace('\\', '/'));

        if (string.IsNullOrWhiteSpace(fileName))
        {
            return null;
        }

        var fullPath = Path.GetFullPath(Path.Combine(_root, fileName));

        // Defense in depth: even after Path.GetFileName above, make sure the
        // combined path really did stay inside the configured root.
        var normalizedRoot = Path.GetFullPath(_root);
        return fullPath.StartsWith(normalizedRoot, StringComparison.Ordinal) ? fullPath : null;
    }
}
