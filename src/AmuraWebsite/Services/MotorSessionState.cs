using System.Text.Json;

namespace AmuraWebsite.Services;

public sealed class MotorSessionState
{
    // Step 1 — client
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Dob { get; set; } = string.Empty; // yyyy-MM-dd
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? KraPin { get; set; }
    public int? ClientId { get; set; }

    // Step 1 — vehicle
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string RegNo { get; set; } = string.Empty;
    public string ChassisNo { get; set; } = string.Empty;
    public string EngineNo { get; set; } = string.Empty;
    public int YearOfManufacture { get; set; }
    public string VehicleType { get; set; } = string.Empty;
    public string BodyType { get; set; } = string.Empty;
    public string FuelType { get; set; } = string.Empty;
    public string CubicCapacity { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string Logbook { get; set; } = string.Empty;
    public int? VehicleId { get; set; }

    // Pricing inputs / results
    public int VehicleClassId { get; set; }
    public int PeriodId { get; set; }
    public int CarryCapacity { get; set; } = 1;

    // Cover type: "TPO" or "COMPREHENSIVE"
    public string CoverType { get; set; } = "TPO";
    public decimal VehicleValue { get; set; }

    // TPO pricing
    public List<TpoPriceOptionDto> PriceOptions { get; set; } = new();

    // Comprehensive pricing
    public ComprehensiveQuoteResponse? ComprehensiveQuote { get; set; }

    // Step 2 — chosen underwriter
    public int? SelectedUnderwriterId { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedPrice { get; set; }
    public int? ProductId { get; set; }

    // Step 3 — purchase + payment
    public int? PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public string? AccountNumber { get; set; }
    public string? PaybillNumber { get; set; }
    public int? PaymentId { get; set; }
    public bool PushSent { get; set; }
}

/// <summary>
/// Thin wrapper around ISession for the Motor flow's state — serializes to
/// JSON under one session key so the 3 steps (Details, Compare, Pay) can
/// share data without a database. Requires session middleware registered
/// in Program.cs (see the setup note that ships alongside this).
/// </summary>
public sealed class MotorSessionStore
{
    private const string SessionKey = "MotorPurchaseState";

    public MotorSessionState Get(ISession session)
    {
        var json = session.GetString(SessionKey);
        if (string.IsNullOrEmpty(json))
        {
            return new MotorSessionState();
        }
        return JsonSerializer.Deserialize<MotorSessionState>(json) ?? new MotorSessionState();
    }

    public void Save(ISession session, MotorSessionState state)
    {
        session.SetString(SessionKey, JsonSerializer.Serialize(state));
    }

    public void Clear(ISession session)
    {
        session.Remove(SessionKey);
    }
}
