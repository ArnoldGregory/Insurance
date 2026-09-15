using System.Text.Json.Serialization;

namespace InsurancePlatform.Infrastructure.Integrations.GovConnect;

/// <summary>Response from GET {Url}/v1/token/generate?grant_type=client_credentials.</summary>
public class GovConnectTokenResponse
{
    [JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }
}

/// <summary>Body sent to POST {Url}/checker/v1/pin.</summary>
public class GovConnectCheckerRequest
{
    [JsonPropertyName("TaxpayerType")]
    public string TaxpayerType { get; set; } = "KE";

    [JsonPropertyName("TaxpayerID")]
    public string TaxpayerID { get; set; } = string.Empty;
}

/// <summary>Response from the checker endpoint. ResponseCode "30000" is the documented "found" code.</summary>
public class GovConnectCheckerResponse
{
    [JsonPropertyName("TaxpayerPIN")]
    public string? TaxpayerPIN { get; set; }

    [JsonPropertyName("TaxpayerName")]
    public string? TaxpayerName { get; set; }

    [JsonPropertyName("ResponseCode")]
    public string? ResponseCode { get; set; }
}
