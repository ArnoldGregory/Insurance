namespace InsurancePlatform.Api.Contracts.Quotes;

/// <summary>
/// Back office uploads one priced option from one underwriter against a
/// quote request. Bound with [FromForm], not [FromBody] - Document needs to
/// be an actual uploaded file (multipart/form-data), not a typed-in path
/// string, so this whole request has to travel as a form post rather than
/// JSON.
/// </summary>
public class CreateQuoteOfferRequest
{
    public long UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }

    /// <summary>Optional - an offer can be recorded before its supporting document is ready.</summary>
    public IFormFile? Document { get; set; }
}

/// <summary>
/// Edits an ACTIVE offer's underwriter/premium, and optionally swaps in a
/// replacement document. Document is nullable/optional here for a
/// different reason than on Create: omitting it means "leave the existing
/// document alone", not "this offer has none" - see
/// QuoteRequestsController.UpdateOffer for how that distinction is made.
/// </summary>
public class UpdateQuoteOfferRequest
{
    public long UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }
    public IFormFile? Document { get; set; }
}

/// <summary>One row inside a batch-create POST - same shape as CreateQuoteOfferRequest, just repeatable.</summary>
public class QuoteOfferBatchCreateItem
{
    public long UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }
    public IFormFile? Document { get; set; }
}

/// <summary>
/// "Add multiple offers, submit once" - bound from multipart/form-data
/// with indexed field names (Offers[0].UnderwriterId, Offers[0].PremiumAmount,
/// Offers[0].Document, Offers[1].UnderwriterId, ...), which ASP.NET Core's
/// default form binder handles natively for a List&lt;T&gt; property - no
/// custom model binder needed. One offer is a valid batch of one, same as
/// the plain (non-batch) CreateQuoteOfferRequest above.
/// </summary>
public class CreateQuoteOfferBatchRequest
{
    public List<QuoteOfferBatchCreateItem> Offers { get; set; } = new();
}

/// <summary>One row inside a batch-update PUT - same shape as UpdateQuoteOfferRequest, plus the id of which offer this row edits (root-addressed batch endpoint, not nested under a single quote request).</summary>
public class QuoteOfferBatchUpdateItem
{
    public long QuoteOfferId { get; set; }
    public long UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }
    public IFormFile? Document { get; set; }
}

/// <summary>
/// Batch edit - lets back office correct several offers on the same quote
/// request in one submission instead of one PUT per row. QuoteRequestId is
/// supplied once at the top level (every offer in one batch is assumed to
/// belong to the same quote request) purely so the offers-comparison email
/// can be re-sent once at the end, not once per edited row - UpdateAsync
/// itself doesn't need it (quote_offer_id alone is enough to find the row).
/// </summary>
public class UpdateQuoteOfferBatchRequest
{
    public long QuoteRequestId { get; set; }
    public List<QuoteOfferBatchUpdateItem> Offers { get; set; } = new();
}
