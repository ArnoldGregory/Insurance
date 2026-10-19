namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Binds the "UnderwriterIntegrations" section of appsettings.json. Decides
/// which underwriters get their certificate from somewhere other than our own
/// DMVIC intermediary call - matched on the underwriter's name, the same way
/// BIMADLINE routes ("directline" / "amaco" / "definite" in the company name).
/// Every integration is disabled by default, so nothing changes until one is
/// switched on.
/// </summary>
public class UnderwriterIntegrationOptions
{
    public const string SectionName = "UnderwriterIntegrations";

    /// <summary>
    /// Optional shared secret insurers (or SCAPI, forwarding for them) must send
    /// in the X-Callback-Key header. Empty = callbacks are accepted without it
    /// (BIMADLINE's behaviour) - set it in production.
    /// </summary>
    public string CallbackSecret { get; set; } = string.Empty;

    public DirectLineIntegrationOptions DirectLine { get; set; } = new();

    public CallbackOnlyIntegrationOptions Amaco { get; set; } = new() { NameContains = "amaco" };

    public CallbackOnlyIntegrationOptions Definite { get; set; } = new() { NameContains = "definite" };

    public bool AnyEnabled => DirectLine.Enabled || Amaco.Enabled || Definite.Enabled;

    /// <summary>Case/space-insensitive "underwriter name contains" check, e.g. "Direct Line Assurance" matches "directline".</summary>
    public static bool NameMatches(string? underwriterName, string? nameContains)
    {
        if (string.IsNullOrWhiteSpace(underwriterName) || string.IsNullOrWhiteSpace(nameContains))
        {
            return false;
        }

        static string Normalize(string value) => value.Replace(" ", string.Empty).ToLowerInvariant();
        return Normalize(underwriterName).Contains(Normalize(nameContains));
    }
}

/// <summary>
/// An insurer that issues on its own side and calls us back with the
/// certificate (AMACO, Definite in BIMADLINE). We only record the request and
/// wait for the callback.
/// </summary>
public class CallbackOnlyIntegrationOptions
{
    public bool Enabled { get; set; }

    public string NameContains { get; set; } = string.Empty;
}

/// <summary>
/// DirectLine certificate generation over SCAPI (interface DIRECTLINE,
/// request_type DirectLineCertificateGeneration). Field values mirror
/// BIMADLINE's live call; the agency-specific codes must come from DirectLine.
/// </summary>
public class DirectLineIntegrationOptions
{
    public bool Enabled { get; set; }

    public string NameContains { get; set; } = "directline";

    /// <summary>Agency code DirectLine assigned to us (BIMADLINE sends its own as "agentCode").</summary>
    public string AgentCode { get; set; } = string.Empty;

    /// <summary>API code DirectLine assigned to us ("api_code").</summary>
    public string ApiCode { get; set; } = string.Empty;

    public string CoverType { get; set; } = "TPO";

    public string PaymentMode { get; set; } = "ACCOUNT";

    public string ClientType { get; set; } = "Individual";

    public string PostalAddress { get; set; } = string.Empty;

    public string Town { get; set; } = string.Empty;

    /// <summary>Notification email sent to DirectLine - empty uses the client's email.</summary>
    public string NotificationEmail { get; set; } = string.Empty;

    /// <summary>Notification phone sent to DirectLine - empty uses the client's phone.</summary>
    public string NotificationPhoneNumber { get; set; } = string.Empty;

    /// <summary>Our vehicle class name (Vehicles.vehicle_type) -> DirectLine "vehicletype" code. Case-insensitive.</summary>
    public Dictionary<string, string> VehicleTypeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Used when the vehicle class has no entry in VehicleTypeMap. Empty = don't post (log and skip).</summary>
    public string DefaultVehicleType { get; set; } = string.Empty;

    public bool TryResolveVehicleType(string? vehicleClass, out string code)
    {
        if (!string.IsNullOrWhiteSpace(vehicleClass))
        {
            foreach (var pair in VehicleTypeMap)
            {
                if (string.Equals(pair.Key, vehicleClass.Trim(), StringComparison.OrdinalIgnoreCase)
                    && !string.IsNullOrWhiteSpace(pair.Value))
                {
                    code = pair.Value;
                    return true;
                }
            }
        }

        code = DefaultVehicleType;
        return !string.IsNullOrWhiteSpace(code);
    }

    /// <summary>
    /// DirectLine's period codes as used by BIMADLINE: 1 = 1 year, 2 = 6 months,
    /// 12 = 1 month, 26 = 2 weeks, 52 = 1 week. Null when the cover length doesn't fit.
    /// </summary>
    public static string? PeriodCode(int durationDays) => durationDays switch
    {
        >= 360 => "1",
        >= 180 => "2",
        >= 28 => "12",
        >= 14 => "26",
        >= 7 => "52",
        _ => null
    };
}
