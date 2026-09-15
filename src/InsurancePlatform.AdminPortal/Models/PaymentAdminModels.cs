using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Payment - one payment attempt against a purchase (a purchase can have several, e.g. a failed STK push followed by a manual Paybill payment).</summary>
public class PaymentItem
{
    public long PaymentId { get; set; }
    public long PurchaseId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string? PayerPhone { get; set; }
    public string? TransactionReference { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime InitiatedOn { get; set; }
    public DateTime? CompletedOn { get; set; }
}

/// <summary>
/// There is no "list every payment" endpoint on the API - only GET
/// /api/payments/by-purchase/{purchaseId} (see PaymentsController's own
/// doc comment: Payments are always viewed in the context of one
/// purchase). So the Payments screen starts with a lookup step, same
/// shape as Clients' 2-step Create - enter a Purchase ID, then see that
/// purchase's payment attempts.
/// </summary>
public class PaymentLookupViewModel
{
    [Required(ErrorMessage = "Enter a purchase ID to look up.")]
    [Display(Name = "Purchase ID")]
    public long? PurchaseId { get; set; }

    public string? ErrorMessage { get; set; }
}

public class PaymentsForPurchaseViewModel
{
    public long PurchaseId { get; set; }
    public List<PaymentItem> Items { get; set; } = new();

    /// <summary>UpdateStatus is CS/SA/AA/SP on the API side - CS is machine-to-machine and never signs into this portal, so SA/AA/SP is what matters here (RoleCodes.QuoteBackoffice).</summary>
    public bool CanUpdateStatus { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    public static readonly string[] StatusOptions = { "PENDING", "SUCCESS", "FAILED" };
}

public class PaymentStatusUpdateViewModel
{
    public long PaymentId { get; set; }
    public long PurchaseId { get; set; }

    [Required]
    public string Status { get; set; } = string.Empty;

    [Display(Name = "Transaction reference (optional)")]
    public string? TransactionReference { get; set; }
}
