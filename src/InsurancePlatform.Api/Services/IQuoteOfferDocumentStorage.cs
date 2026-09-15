namespace InsurancePlatform.Api.Services;

/// <summary>
/// Saves an uploaded underwriter-quote document (PDF/image/Word doc) to
/// wherever this deployment keeps them (a configurable shared folder - see
/// LocalQuoteOfferDocumentStorage), and hands back the relative storage key
/// to store in QuoteOffers.document_path. Kept behind an interface so a
/// future move to real blob storage (Azure Blob/S3) only means writing a new
/// class and changing one DI registration in Program.cs -
/// QuoteRequestsController never needs to know which one is behind it.
/// </summary>
public interface IQuoteOfferDocumentStorage
{
    /// <summary>
    /// Validates and saves the file. Throws InvalidOperationException (caught
    /// by the controller and turned into a normal ApiResponse failure, same
    /// as any other validation error in this codebase) if the file is too
    /// large or an unsupported type.
    /// </summary>
    Task<string> SaveAsync(IFormFile file);

    /// <summary>
    /// Opens a previously saved document for reading - null when the key is
    /// empty/unknown or the file is missing on disk. Caller owns disposing
    /// the returned stream. Used both by the authenticated download endpoint
    /// and by the offers-comparison email attachment flow.
    /// </summary>
    Task<Stream?> OpenAsync(string? storagePath);

    /// <summary>The on-disk filename portion of a stored path (e.g. "abc123.pdf") - null for an unusable/empty key.</summary>
    string? GetFileName(string? storagePath);
}
