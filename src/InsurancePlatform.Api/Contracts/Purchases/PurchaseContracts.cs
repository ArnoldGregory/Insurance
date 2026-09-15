namespace InsurancePlatform.Api.Contracts.Purchases;

/// <summary>Buys a policy - either Motor (VehicleId + snapshot fields) or a manual-quote product (QuoteOfferId).</summary>
// PurchasedByUserId/ChannelServiceAccountId are NOT here - the server
// always derives them from the caller's own JWT (CurrentUserId, resolved
// against CurrentRoleCode), same "never trust the body for who's acting"
// rule ClientsController.Create uses for registered_by_user_id.
public class CreatePurchaseRequest
{
    public long ProductId { get; set; }
    public long ClientId { get; set; }
    public long UnderwriterId { get; set; }

    /// <summary>Required for manual-quote products - must already be SELECTED (usp_QuoteOffer_Select).</summary>
    public long? QuoteOfferId { get; set; }
    public decimal PremiumAmount { get; set; }
    public long PeriodId { get; set; }
    public DateTime StartDate { get; set; }

    /// <summary>Leave null to auto-generate (POL-yyyyMMdd-00000001 pattern).</summary>
    public string? PolicyNumber { get; set; }

    // Motor-only snapshot fields - leave all null for a manual-quote purchase.
    public long? VehicleId { get; set; }
    public decimal? VehicleValue { get; set; }
    public decimal? Tonnage { get; set; }
    public long? LicensedToCarry { get; set; }
    public string? AntiTheft { get; set; }
    public string? Risk { get; set; }
    public decimal? SnapshotAmount { get; set; }
}

public class UpdatePurchaseStatusRequest
{
    /// <summary>ACTIVE, EXPIRED or CANCELLED.</summary>
    public string Status { get; set; } = string.Empty;
}
