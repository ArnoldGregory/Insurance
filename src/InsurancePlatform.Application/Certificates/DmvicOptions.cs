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
    /// Optional per-vehicle-type override map: uppercase vehicle_type (e.g.
    /// "COMMERCIAL") -> "&lt;request_type&gt;|&lt;type_of_certificate&gt;".
    /// Vehicle types not listed use RequestType/TypeOfCertificate above.
    /// </summary>
    public Dictionary<string, string> VehicleTypeMap { get; set; } = new();
}