namespace InsurancePlatform.Domain.Entities;

/// <summary>usp_UnderwriterCert_GetPurchaseData's row - what a non-DMVIC insurer integration (DirectLine etc.) needs about a purchase.</summary>
public class UnderwriterCertPurchaseData
{
    public long PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal PremiumAmount { get; set; }
    public string? NtsaCertificateNo { get; set; }
    public string? PaymentStatus { get; set; }
    public int DurationDays { get; set; }

    public string? Policyholder { get; set; }
    public string? IdNo { get; set; }
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
    public string? CubicCapacity { get; set; }

    public decimal? VehicleValue { get; set; }
    public decimal? Tonnage { get; set; }
    public long? LicensedToCarry { get; set; }

    public long UnderwriterId { get; set; }
    public string? UnderwriterName { get; set; }
}

/// <summary>A row of UnderwriterCertificateRequests as returned by usp_UnderwriterCert_FindForCallback.</summary>
public class UnderwriterCertRequest
{
    public long RequestId { get; set; }
    public long PurchaseId { get; set; }
    public string Integration { get; set; } = string.Empty;
    public string ExternalRef { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? CertNo { get; set; }
}

/// <summary>UnderwriterCertificateRequests.status values.</summary>
public static class UnderwriterCertStatus
{
    public const string Pending = "PENDING";
    public const string Posted = "POSTED";
    public const string AwaitingCallback = "AWAITING_CALLBACK";
    public const string Issued = "ISSUED";
    public const string Failed = "FAILED";
}
