namespace InsurancePlatform.Domain.Entities;

/// <summary>One payment attempt against a purchase - usp_Payment_GetByPurchase's row shape.</summary>
public class Payment
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

/// <summary>usp_Payment_GetSummary's single-row shape - dashboard stat-card counts + total amount collected.</summary>
public class PaymentDashboardSummary
{
    public long PendingCount { get; set; }
    public long SuccessCount { get; set; }
    public long FailedCount { get; set; }
    public long TotalCount { get; set; }

    /// <summary>Sum of SUCCESS payments only - PENDING/FAILED never contributed real money.</summary>
    public decimal TotalCollected { get; set; }
}
