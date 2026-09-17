using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.AspNetCore.Http;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>
/// Mirrors InsurancePlatform.Domain.Entities.QuoteRequest - the shared
/// parent row for all 5 non-Motor quote products (Medical Individual/
/// Corporate, Professional Indemnity, Travel, Domestic). Used both as a
/// list row (GET /api/quoterequests) and the parent half of a detail page
/// (GET /api/quoterequests/{id}) - the API uses one shape for both, so this
/// does too.
/// </summary>
public class QuoteRequestItem
{
    public long QuoteRequestId { get; set; }

    /// <summary>Short external-facing tracking code (e.g. "MI-7F3K2A") - this is what's shown to users/support instead of QuoteRequestId.</summary>
    public string? RefNo { get; set; }

    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public long? ClientId { get; set; }
    public long? RequestedByUserId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public long? AssignedBackofficeUserId { get; set; }
    public DateTime CreatedOn { get; set; }

    /// <summary>
    /// NOT part of the API response - filled in by QuoteRequestsController
    /// after the fact, by matching AssignedBackofficeUserId against the
    /// Support staff list it already fetched for the assign dropdown. Null
    /// either when unassigned, or when it's assigned to someone outside
    /// that list (e.g. a SuperAdmin/AgentAdmin who used "Assign to me" -
    /// those roles aren't in the Support picker, so their names aren't
    /// resolved here) - the view falls back to "User #{id}" in that case.
    /// </summary>
    public string? AssignedToName { get; set; }
}

public class QuoteRequestListPage
{
    public long TotalCount { get; set; }
    public List<QuoteRequestItem> Items { get; set; } = new();
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.QuoteOffer.</summary>
public class QuoteOfferItem
{
    public long QuoteOfferId { get; set; }
    public long QuoteRequestId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public string? DocumentPath { get; set; }
    public long UploadedByUserId { get; set; }
    public DateTime UploadedOn { get; set; }
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// NOT part of the API response - filled in by QuoteRequestsController
    /// from DocumentPath, which is relative to the API's own origin (a
    /// different port/host than this portal). Null when DocumentPath itself
    /// is null (no document uploaded for this offer).
    /// </summary>
    public string? DocumentUrl { get; set; }
}

/// <summary>Minimal mirror of InsurancePlatform.Domain.Entities.UnderwriterSummary - just what the "add offer" form's underwriter picker needs.</summary>
public class UnderwriterOption
{
    public long UnderwriterId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.StaffOption - just enough to populate the "assign to a specific Support person" dropdown.</summary>
public class StaffOption
{
    public long UserId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.QuoteRequestProductSummary - the list screen's per-product pending/in-progress/total header cards.</summary>
public class QuoteRequestProductSummary
{
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public long PendingCount { get; set; }
    public long InProgressCount { get; set; }
    public long TotalCount { get; set; }
}

public class QuoteRequestIndexViewModel
{
    public List<QuoteRequestItem> Items { get; set; } = new();
    public long TotalCount { get; set; }
    public string? Status { get; set; }
    public long? ProductId { get; set; }

    /// <summary>True when this list was reached via the notification bell's "assigned to you" link - carried through to the pager links so paging doesn't silently drop the filter.</summary>
    public bool Mine { get; set; }

    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    /// <summary>
    /// Per-product pending/in-progress/total counts for the summary cards -
    /// also doubles as the product filter dropdown's option list, so there's
    /// no separate "list of products" call just for that.
    /// </summary>
    public List<QuoteRequestProductSummary> Summary { get; set; } = new();

    public int TotalPages => PageSize <= 0 ? 1 : (int)Math.Ceiling(TotalCount / (double)PageSize);

    /// <summary>Every status usp_QuoteRequest_GetList's own filter accepts, for the filter dropdown.</summary>
    public static readonly string[] StatusOptions = { "PENDING", "IN_PROGRESS", "QUOTED", "EXPIRED", "CONVERTED" };
}

/// <summary>
/// GET /api/quoterequests/{id}/detail returns a DIFFERENT shape per
/// ProductCode (5 different detail tables - MedicalIndividual/
/// MedicalCorporate/ProfessionalIndemnity/Travel/Domestic each has its own
/// columns). Rather than hand-maintaining 5 separate C# DTOs that could
/// silently drift out of sync with the API, this deserializes the detail
/// payload into a plain Dictionary&lt;string, JsonElement&gt; and the view
/// just renders whatever key/value pairs come back - works for any of the
/// 5 shapes today, and for a 6th product added later, with no C# change
/// needed here.
/// </summary>
public class QuoteRequestDetailViewModel
{
    public QuoteRequestItem Request { get; set; } = new();
    public Dictionary<string, JsonElement> TypeDetail { get; set; } = new();
    public List<QuoteOfferItem> Offers { get; set; } = new();
    public List<UnderwriterOption> UnderwriterOptions { get; set; } = new();

    /// <summary>Support (SP) staff, for the "assign to a specific person" dropdown - see the "Assign scope" decision in QuoteRequestsController's doc comment.</summary>
    public List<StaffOption> AssignableStaff { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

public class CreateQuoteOfferViewModel
{
    public long QuoteRequestId { get; set; }

    [Required(ErrorMessage = "Pick an underwriter.")]
    [Display(Name = "Underwriter")]
    public long? UnderwriterId { get; set; }

    [Required(ErrorMessage = "Enter the premium amount.")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Premium must be greater than 0.")]
    [Display(Name = "Premium amount")]
    public decimal PremiumAmount { get; set; }

    [Display(Name = "Document (optional)")]
    public IFormFile? Document { get; set; }

    public string? ErrorMessage { get; set; }
}

/// <summary>Same shape as CreateQuoteOfferViewModel, plus which offer is being edited - Document here means "replace the existing file", not "this offer has none".</summary>
public class EditQuoteOfferViewModel
{
    public long QuoteOfferId { get; set; }
    public long QuoteRequestId { get; set; }

    [Required(ErrorMessage = "Pick an underwriter.")]
    [Display(Name = "Underwriter")]
    public long? UnderwriterId { get; set; }

    [Required(ErrorMessage = "Enter the premium amount.")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Premium must be greater than 0.")]
    [Display(Name = "Premium amount")]
    public decimal PremiumAmount { get; set; }

    [Display(Name = "Replace document (optional)")]
    public IFormFile? Document { get; set; }

    public string? ErrorMessage { get; set; }
}

/// <summary>
/// One row inside the "Add offer(s)" modal's dynamic form - Details.cshtml
/// lets a back-office user add several offers at once ("add multiple or
/// even single") instead of one POST per offer, per the feature request.
/// Rows are rendered client-side from a &lt;template&gt; (see Details.cshtml's
/// PageScripts) with indexed field names (Offers[0].UnderwriterId,
/// Offers[0].Document, Offers[1]...) - the default MVC model binder handles
/// binding a form post like that into this List&lt;T&gt; property natively,
/// same as the API side's own CreateQuoteOfferBatchRequest.
/// </summary>
public class QuoteOfferBatchCreateRowViewModel
{
    public long? UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }
    public IFormFile? Document { get; set; }
}

public class CreateQuoteOfferBatchViewModel
{
    public long QuoteRequestId { get; set; }
    public List<QuoteOfferBatchCreateRowViewModel> Offers { get; set; } = new();
}

/// <summary>One row inside the "Edit selected offer(s)" modal - same idea as QuoteOfferBatchCreateRowViewModel, plus which existing offer this row edits.</summary>
public class QuoteOfferBatchEditRowViewModel
{
    public long QuoteOfferId { get; set; }
    public long? UnderwriterId { get; set; }
    public decimal PremiumAmount { get; set; }
    public IFormFile? Document { get; set; }
}

public class EditQuoteOfferBatchViewModel
{
    public long QuoteRequestId { get; set; }
    public List<QuoteOfferBatchEditRowViewModel> Offers { get; set; } = new();
}

/// <summary>One structured add-on/rider line; Name passes the "blank names are dropped server-side" rule.</summary>
public class QuoteOfferRiderItem
{
    [Display(Name = "Add-on name")]
    public string Name { get; set; } = string.Empty;

    [Display(Name = "Amount (KSh, optional)")]
    public decimal? Amount { get; set; }

    [Display(Name = "Note (optional)")]
    public string? Note { get; set; }
}

/// <summary>
/// Add-ons editor - one offer's whole list is replaced in a single PUT to
/// /api/quote-offers/{id}/riders (the old set is soft-deleted server-side).
/// QuoteOfferId/QuoteRequestId/UnderwriterName/PremiumAmount travel as query
/// parameters from the offer row's link (same "no single-offer endpoint"
/// reasoning as EditOffer), Prefixed with the currently-saved add-ons from
/// GET /api/quoterequests/{quoteRequestId}/offers/{quoteOfferId}/riders.
/// </summary>
public class OfferRidersEditViewModel
{
    public long QuoteOfferId { get; set; }
    public long QuoteRequestId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public List<QuoteOfferRiderItem> Riders { get; set; } = new();
    public string? ErrorMessage { get; set; }
}
