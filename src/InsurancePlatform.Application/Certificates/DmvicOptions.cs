namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// Configuration for the NTSA/D-MVIC official motor certificate issuance -
/// bound to the "Dmvic" appsettings.json section. Values that are the same
/// for every private-car issuance live here (request type, certificate
/// type, cover type, notification contact); per-underwriter membership is
/// read from Underwriters.dmvic_code instead (NTSA member id).
/// </summary>
public sealed class DmvicOptions
{
    /// <summary>Global on/off switch for the best-effort NTSA issuance step. When false only the internal HTML certificate is generated.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>SCAPI DMVICINTERMEDIARY request_type for this product class. Defaults to the private-car flow (issuance_type_c_cert).</summary>
    public string RequestType { get; set; } = "issuance_type_c_cert";

    /// <summary>NTSA "TypeOfCertificate" value for the configured request_type (e.g. "Private Car" for issuance_type_c_cert).</summary>
    public string TypeOfCertificate { get; set; } = "Private Car";

    /// <summary>NTSA "Typeofcover" value (BIMADLINE's insurance_category id - 1 = Third Party Only (TPO), 3 = Comprehensive).</summary>
    public string TypeOfCover { get; set; } = "3";

    /// <summary>Email NTSA sends the issued certificate to. Leave blank to pass the notification email config on the server.</summary>
    public string NotificationEmail { get; set; } = string.Empty;

    /// <summary>Contact phone number to include on the certificate request (mirrors BIMADLINE's agent-number approach).</summary>
    public string NotificationPhoneNumber { get; set; } = string.Empty;

    /// <summary>
    /// When true, calls NTSA's validate_type_*_cert pre-check before issuing
    /// and only proceeds if it reports success (mirrors BIMADLINE). Off by
    /// default because issuance works without it; enable to get richer
    /// pre-issuance validation errors.
    /// </summary>
    public bool ValidateBeforeIssue { get; set; }

    /// <summary>
    /// When true, runs validate_double_insurance before issuing and refuses
    /// to certify a vehicle NTSA reports as already covered (mirrors
    /// BIMADLINE's DoubleIssuanceCheck). Off by default.
    /// </summary>
    public bool CheckDoubleIssuance { get; set; }

    /// <summary>
    /// Optional per-vehicle-type override map: uppercase vehicle_type (e.g.
    /// "COMMERCIAL") -> "&lt;request_type&gt;|&lt;type_of_certificate&gt;".
    /// Overrides an entry in the built-in class map below. Vehicle types not
    /// listed use RequestType/TypeOfCertificate above, unless they are a known
    /// class shape we simply have not mapped yet (see TryResolveVehicleType).
    /// </summary>
    public Dictionary<string, string> VehicleTypeMap { get; set; } = new();

    /// <summary>
    /// Built-in NTSA certificate-type mapping, keyed on the motor vehicle
    /// class name (the value BIMADLINE's wizard and our website stamp onto
    /// Vehicles.vehicle_type). Mirrors BIMADLINE's b_dmvic_cert_type table
    /// (mysql_2025_08_13.sql:3085-3097), which is the authoritative source:
    /// the right-hand value is the NTSA TypeOfCertificate/VehicleType code for
    /// the class, except type_c which has no code (null) and uses the label.
    /// Lives here rather than in appsettings because .NET config treats ':' as
    /// a section separator, so class names containing ':' could not be bound
    /// as dictionary keys.
    /// </summary>
    private static readonly IReadOnlyDictionary<string, (string RequestType, string CertificateType)> VehicleClassCertificateMap =
        new Dictionary<string, (string, string)>(StringComparer.OrdinalIgnoreCase)
        {
            ["PRIVATE"] = ("issuance_type_c_cert", "Private Car"),
            ["PRIVATE CAR"] = ("issuance_type_c_cert", "Private Car"),
            ["PSV-BUS"] = ("issuance_type_a_cert", "6"),                 // Type A Bus
            ["PSV-MATATU"] = ("issuance_type_a_cert", "1"),              // Class A PSV Unmarked
            ["PSV-TAXI / TUK TUK"] = ("issuance_type_a_cert", "8"),      // Type A Taxi
            ["PSV-PRIVATE HIRE/UBER"] = ("issuance_type_a_cert", "1"),   // Class A PSV Unmarked
            ["MOTOR COMMERCIAL:OWN GOODS"] = ("issuance_type_b_cert", "1"),
            ["MOTOR COMMERCIAL:GENERAL"] = ("issuance_type_b_cert", "2"),
            ["MOTOR COMMERCIAL:INSTITUTION"] = ("issuance_type_b_cert", "3"),
            ["MOTOR COMMERCIAL:TANKERS & SPECIFIED TRAILER"] = ("issuance_type_b_cert", "5"),
            ["MOTOR COMMERCIAL:PRIME MOVER"] = ("issuance_type_b_cert", "4"),
            ["MOTOR COMMERCIAL:TRAILER"] = ("issuance_type_b_cert", "4"),
            ["MOTOR COMMERCIAL:TRACTOR"] = ("issuance_type_b_cert", "4"),
            ["MOTORCYCLE:PRIVATE"] = ("issuance_type_d_cert", "4"),      // Motor Cycle
            ["MOTORCYCLE:PSV"] = ("issuance_type_d_cert", "9"),          // PSV Motorcycle
        };

    /// <summary>
    /// Resolves the (request_type, type_of_certificate) pair for a vehicle.
    /// Order: an explicit VehicleTypeMap config override, then the built-in
    /// class map, then the configured default for a blank vehicle type.
    /// Returns false only for a non-blank vehicle type that is neither
    /// configured nor known, so the caller can refuse issuance instead of
    /// minting a certificate of the wrong type.
    /// </summary>
    public bool TryResolveVehicleType(string? vehicleType, out string requestType, out string typeOfCertificate)
    {
        requestType = RequestType;
        typeOfCertificate = TypeOfCertificate;

        var key = vehicleType?.Trim().ToUpperInvariant() ?? string.Empty;
        if (key.Length == 0)
        {
            return true;
        }

        if (VehicleTypeMap.TryGetValue(key, out var mapping))
        {
            var parts = mapping.Split('|', 2, StringSplitOptions.TrimEntries);
            if (parts.Length == 2 && !string.IsNullOrWhiteSpace(parts[0]))
            {
                requestType = parts[0];
                typeOfCertificate = parts[1];
                return true;
            }
        }

        if (VehicleClassCertificateMap.TryGetValue(key, out var mapped))
        {
            requestType = mapped.RequestType;
            typeOfCertificate = mapped.CertificateType;
            return true;
        }

        return false;
    }
}