namespace InsurancePlatform.Infrastructure.Integrations.Daraja;

/// <summary>
/// Settings for the direct Safaricom Daraja transport, bound from the
/// "Daraja" section of appsettings.json. Left empty by default - the
/// M-Pesa flow keeps using the SCAPI gateway until these are filled in
/// (and Mpesa:Transport is switched to "Daraja").
/// </summary>
public class DarajaSettings
{
    /// <summary>Daraja base URL. Production: https://api.safaricom.co.ke - Sandbox: https://sandbox.safaricom.co.ke</summary>
    public string BaseUrl { get; set; } = "https://api.safaricom.co.ke";

    public string ConsumerKey { get; set; } = string.Empty;
    public string ConsumerSecret { get; set; } = string.Empty;

    /// <summary>Paybill pass key - goes into the encoded Password field, never sent as-is.</summary>
    public string PassKey { get; set; } = string.Empty;

    /// <summary>The business short code (paybill) the push is billed to.</summary>
    public string BusinessShortCode { get; set; } = string.Empty;
}
