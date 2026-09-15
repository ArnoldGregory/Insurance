namespace InsurancePlatform.Application.Integrations;

/// <summary>
/// GovConnect (KRA PIN checker) - a completely separate government gateway
/// from SCAPI, with its own auth shape (Basic auth to get a Bearer token,
/// then POST with that token) and its own vendor quirks. Signature only
/// uses plain types, so this interface lives here (Application) while the
/// real implementation (GovConnectClient, using HttpClient) lives in
/// Infrastructure - same placement rule as IScapiGatewayClient.
/// </summary>
public interface ITaxpayerLookupClient
{
    /// <summary>
    /// Returns null if GovConnect has no record for this ID number, the
    /// lookup fails, or the gateway is unreachable - this is always a
    /// best-effort enrichment, never something callers should treat as
    /// authoritative or required to succeed.
    /// </summary>
    Task<TaxpayerLookupResult?> LookupAsync(string idNo);
}

public class TaxpayerLookupResult
{
    public string Pin { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
}
