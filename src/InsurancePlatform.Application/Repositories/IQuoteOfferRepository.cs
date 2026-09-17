using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IQuoteOfferRepository
{
    Task<StoredProcResult<long?>> CreateAsync(long quoteRequestId, long underwriterId, decimal premiumAmount, string? documentPath, long uploadedByUserId);

    Task<StoredProcResult<List<QuoteOffer>>> GetListByRequestAsync(long quoteRequestId);

    Task<StoredProcResult> SelectAsync(long quoteOfferId, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_QuoteOffer_Update. Only ACTIVE offers can be edited (see the
    /// proc's own comment). replaceDocument controls whether documentPath
    /// actually overwrites the stored value or is ignored - lets the API
    /// layer send "keep the existing file" vs. "here's a new one" without a
    /// magic sentinel value.
    /// </summary>
    Task<StoredProcResult> UpdateAsync(long quoteOfferId, long underwriterId, decimal premiumAmount, string? documentPath, bool replaceDocument, long actorId);

    /// <summary>Wraps usp_QuoteOffer_Delete (soft delete). Only ACTIVE offers can be deleted.</summary>
    Task<StoredProcResult> DeleteAsync(long quoteOfferId, long actorId);

    Task<StoredProcResult<QuoteOffer?>> GetByIdAsync(long quoteOfferId);

    /// <summary>
    /// Wraps usp_QuoteOfferRider_Replace - replaces an offer's whole add-on
    /// set in one call (old set is soft-deleted). riders with a blank name
    /// are dropped server-side; an empty list clears the offer's add-ons.
    /// </summary>
    Task<StoredProcResult> ReplaceRidersAsync(long quoteOfferId, List<QuoteOfferRider> riders, long actorId);

    /// <summary>Wraps usp_QuoteOfferRider_GetByOffer - the ACTIVE add-on set for an offer (empty when it has none).</summary>
    Task<StoredProcResult<List<QuoteOfferRider>>> GetRidersByOfferAsync(long quoteOfferId);
}
