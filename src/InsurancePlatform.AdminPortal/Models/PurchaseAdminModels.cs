using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.PurchaseSummary - usp_Purchase_GetList's row shape (no vehicle snapshot, see Purchase's own doc comment for why that's a separate, heavier type).</summary>
public class PurchaseSummaryItem
{
    public long PurchaseId { get; set; }
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public long ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public long? PurchasedByUserId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public string? PolicyNumber { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

public class PurchaseListPage
{
    public long TotalCount { get; set; }
    public List<PurchaseSummaryItem> Items { get; set; } = new();
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.VehiclePurchaseSnapshot - Motor-only, frozen at purchase time.</summary>
public class VehiclePurchaseSnapshotItem
{
    public long SnapshotId { get; set; }
    public long VehicleId { get; set; }
    public decimal? VehicleValue { get; set; }
    public decimal? Tonnage { get; set; }
    public long? LicensedToCarry { get; set; }
    public string? AntiTheft { get; set; }
    public string? Risk { get; set; }
    public decimal? Amount { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Purchase - GET /api/purchases/{id}'s full row, including the Motor-only VehicleSnapshot (null for every non-Motor purchase).</summary>
public class PurchaseDetail
{
    public long PurchaseId { get; set; }
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public long ClientId { get; set; }
    public long? PurchasedByUserId { get; set; }
    public long? ChannelServiceAccountId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public long? QuoteOfferId { get; set; }
    public decimal PremiumAmount { get; set; }
    public long PeriodId { get; set; }
    public string PeriodName { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? PolicyNumber { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public VehiclePurchaseSnapshotItem? VehicleSnapshot { get; set; }
}

public class PurchaseIndexViewModel
{
    public List<PurchaseSummaryItem> Items { get; set; } = new();
    public long TotalCount { get; set; }
    public string? Status { get; set; }
    public string? PaymentStatus { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    /// <summary>UPDATE_STATUS is SA/AA/SP - not AG. See RoleCodes.QuoteBackoffice.</summary>
    public bool CanChangeStatus { get; set; }

    public int TotalPages => PageSize <= 0 ? 1 : (int)Math.Ceiling(TotalCount / (double)PageSize);

    public static readonly string[] StatusOptions = { "ACTIVE", "EXPIRED", "CANCELLED" };
    public static readonly string[] PaymentStatusOptions = { "PENDING", "PAID" };
}

public class PurchaseStatusUpdateViewModel
{
    public long PurchaseId { get; set; }

    [Required]
    public string Status { get; set; } = string.Empty;
}

public class PurchaseJourneyViewModel
{
    public long PurchaseId { get; set; }
    public PurchaseSummaryModel? Summary { get; set; }
    public List<PurchaseTimelineEventModel> Timeline { get; set; } = new();
    public List<PurchasePaymentModel> Payments { get; set; } = new();
    public PurchaseVehicleModel? Vehicle { get; set; }
    public List<PurchaseRelatedModel> RelatedPurchases { get; set; } = new();
}

public class PurchaseSummaryModel
{
    public string PolicyNumber { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime CreatedOn { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public string ClientIdNo { get; set; } = string.Empty;
    public string ClientPhone { get; set; } = string.Empty;
    public string ClientEmail { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string UnderwriterName { get; set; } = string.Empty;
    public string CreatedByName { get; set; } = string.Empty;
}

public class PurchaseTimelineEventModel
{
    public string EventType { get; set; } = string.Empty;
    public int StepOrder { get; set; }
    public long RefId { get; set; }
    public DateTime EventTime { get; set; }
    public string EventDataJson { get; set; } = "{}";
}

public class PurchasePaymentModel
{
    public long PaymentId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string PayerPhone { get; set; } = string.Empty;
    public string TransactionReference { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime InitiatedOn { get; set; }
    public DateTime? CompletedOn { get; set; }
}

public class PurchaseVehicleModel
{
    public decimal? VehicleValue { get; set; }
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string RegNo { get; set; } = string.Empty;
    public string ChassisNo { get; set; } = string.Empty;
    public int? YearOfManufacture { get; set; }
}

public class PurchaseRelatedModel
{
    public long PurchaseId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
}
