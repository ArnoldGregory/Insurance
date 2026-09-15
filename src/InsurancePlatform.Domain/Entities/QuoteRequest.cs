namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// The shared parent row - usp_QuoteRequest_GetById/GetList's shape. The
/// caller reads ProductCode off this to know which of the five
/// Get*DetailAsync calls to make next for the type-specific fields.
/// </summary>
public class QuoteRequest
{
    public long QuoteRequestId { get; set; }

    /// <summary>
    /// Short, external-facing tracking code (e.g. "MI-7F3K2A") - generated
    /// once at creation by the owning usp_QuoteRequest&lt;Type&gt;_Create
    /// proc. This is what should be SHOWN to users/support instead of
    /// QuoteRequestId - the numeric id remains the real primary key for
    /// every internal join/FK, unchanged.
    /// </summary>
    public string? RefNo { get; set; }

    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public long? ClientId { get; set; }
    public long? RequestedByUserId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public long? AssignedBackofficeUserId { get; set; }
    public DateTime CreatedOn { get; set; }
}

/// <summary>Returned by every usp_QuoteRequest&lt;Type&gt;_Create proc - the new row's id plus its generated ref_no, handed straight back so a client-facing caller can show "Your reference: MI-7F3K2A" immediately without a follow-up GetById call.</summary>
public class QuoteRequestCreateResult
{
    public long QuoteRequestId { get; set; }
    public string? RefNo { get; set; }
}

/// <summary>Paginated wrapper for usp_QuoteRequest_GetList - same shape as ClientListPage.</summary>
public class QuoteRequestListPage
{
    public long TotalCount { get; set; }
    public List<QuoteRequest> Items { get; set; } = new();
}

/// <summary>
/// One row per manual-quote product from usp_QuoteRequest_GetSummary - the
/// work-queue header counts the Quote Requests list screen shows (e.g.
/// "MED_IND: 3 pending, 1 in progress, 9 total"). PENDING+IN_PROGRESS aren't
/// the only statuses a request can be in (QUOTED/EXPIRED/CONVERTED exist
/// too) - TotalCount is every status combined, not just those two added
/// together.
/// </summary>
public class QuoteRequestProductSummary
{
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public long PendingCount { get; set; }
    public long InProgressCount { get; set; }
    public long TotalCount { get; set; }
}
