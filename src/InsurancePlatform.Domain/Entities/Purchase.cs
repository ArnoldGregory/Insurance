namespace InsurancePlatform.Domain.Entities;

/// <summary>Full purchase record - usp_Purchase_GetById's shape, including its Motor-only snapshot child rows.</summary>
public class Purchase
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

    public string CertificateStatus { get; set; } = string.Empty;
    public DateTime? CertificateGeneratedOn { get; set; }
    public string? CertificateNumber { get; set; }

    /// <summary>NTSA/D-MVIC official certificate number (actualCNo from the issuance response) - null until DMVIC issue succeeds.</summary>
    public string? NtsaCertificateNo { get; set; }

    public string? NtsaTransactionNo { get; set; }
    public DateTime? NtsaIssuedOn { get; set; }

    public string? ClientName { get; set; }
    public string? ClientIdNo { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientEmail { get; set; }
    public string? ProductName { get; set; }

    /// <summary>Vehicle identity (Vehicles via VehiclePurchaseSnapshot join) - null for non-Motor purchases.</summary>
    public string? VehicleRegNo { get; set; }
    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }

    /// <summary>Null for every non-Motor purchase - populated from usp_Purchase_GetById's second result set.</summary>
    public VehiclePurchaseSnapshot? VehicleSnapshot { get; set; }
}

/// <summary>usp_Purchase_GetList's row shape - a lighter view for the list screen, no snapshot.</summary>
public class PurchaseSummary
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

/// <summary>Paginated wrapper for usp_Purchase_GetList - same shape as ClientListPage.</summary>
public class PurchaseListPage
{
    public long TotalCount { get; set; }
    public List<PurchaseSummary> Items { get; set; } = new();
}

/// <summary>usp_Purchase_Create's proc-specific OUT params, plus PaybillNumber added by PurchasesController.</summary>
public class PurchaseCreateResult
{
    public long PurchaseId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
    public DateTime EndDate { get; set; }

    /// <summary>The M-Pesa paybill account reference for this purchase - "{VehicleRegNo}#{purchase_id}" for Motor, "{ClientIdNo}#{purchase_id}" otherwise. From usp_Purchase_Create's o_account_number.</summary>
    public string AccountNumber { get; set; } = string.Empty;

    /// <summary>The M-Pesa paybill business short code - a fixed environment setting (Mpesa:BusinessShortCode in appsettings.json), NOT purchase-specific data, so it's set by PurchasesController after the repository call, not by the stored proc.</summary>
    public string PaybillNumber { get; set; } = string.Empty;
}

/// <summary>usp_Purchase_GetSummary's single-row shape - dashboard stat-card counts, not a list. Named "DashboardSummary" (not "Summary") because PurchaseSummary above is already taken by usp_Purchase_GetList's row shape.</summary>
public class PurchaseDashboardSummary
{
    public long ActiveCount { get; set; }
    public long ExpiredCount { get; set; }
    public long CancelledCount { get; set; }
    public long PaymentPendingCount { get; set; }
    public long PaymentPaidCount { get; set; }
    public long PaymentFailedCount { get; set; }
    public long TotalCount { get; set; }
}

/// <summary>usp_Purchase_GetPeriodTotals's single-row shape - "Monthly Purchases"/"Daily Purchases" dashboard widgets.</summary>
public class PurchasePeriodTotals
{
    public long TodayCount { get; set; }
    public decimal TodayPremiumTotal { get; set; }
    public long MonthCount { get; set; }
    public decimal MonthPremiumTotal { get; set; }
}

/// <summary>usp_Purchase_GetByUnderwriter's row shape - top 10 underwriters by premium written.</summary>
public class UnderwriterSalesSummary
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>usp_Purchase_GetByProduct's row shape - every product's purchase count + premium total.</summary>
public class ProductSalesSummary
{
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>usp_Purchase_GetMonthlyTrend's row shape - always exactly 6 rows, oldest to newest, zero-filled for months with no purchases.</summary>
public class MonthlyTrendPoint
{
    public string YearMonth { get; set; } = string.Empty;
    public string MonthLabel { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>usp_Purchase_GetTopAgents's row shape - top 10 agents by policies sold.</summary>
public class TopAgentSummary
{
    public long AgentUserId { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>The Motor-only child row - vehicle details frozen as-of the purchase date.</summary>
public class VehiclePurchaseSnapshot
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

/// <summary>
/// usp_Purchase_GetDmvicData's row shape - everything the NTSA/D-MVIC
/// issuance call needs about a purchase, joined from the purchase itself,
/// the client, the vehicle snapshot and the underwriter. Vehicle/client
/// fields are null for non-Motor purchases (LEFT JOINs), so the caller can
/// skip cleanly instead of the proc erroring.
/// </summary>
public class PurchaseDmvicData
{
    public long PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal PremiumAmount { get; set; }
    public string? CertificateNumber { get; set; }
    public string? NtsaCertificateNo { get; set; }
    public string? NtsaTransactionNo { get; set; }

    public string? Policyholder { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientEmail { get; set; }
    public string? KraPin { get; set; }

    public string? RegNo { get; set; }
    public string? Make { get; set; }
    public string? Model { get; set; }
    public string? ChassisNo { get; set; }
    public string? EngineNo { get; set; }
    public int? YearOfManufacture { get; set; }
    public string? PBodyType { get; set; }
    public string? VehicleType { get; set; }

    public decimal? VehicleValue { get; set; }
    public long? LicensedToCarry { get; set; }

    public string? MemberCompanyId { get; set; }
    public string? UnderwriterName { get; set; }
}

/// <summary>usp_Purchase_GetVehicleCertificateDocument's row shape - the latest official NTSA document record for a purchase.</summary>
public class VehicleCertificateDocument
{
    public long CertDocId { get; set; }
    public long PurchaseId { get; set; }
    public string? TransactionNo { get; set; }
    public string? CertNo { get; set; }
    public string? Email { get; set; }
    public string? CertDownloadUrl { get; set; }
    public string? CertData { get; set; }
    public bool CertGenerated { get; set; }
    public string? CertStatus { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime CreatedOn { get; set; }
}
