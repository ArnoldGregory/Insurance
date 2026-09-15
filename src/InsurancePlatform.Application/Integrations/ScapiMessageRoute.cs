using System.Text.Json.Serialization;

namespace InsurancePlatform.Application.Integrations;


public class ScapiMessageRoute
{
    [JsonPropertyName("interface")]
    public string Interface { get; set; } = string.Empty;

    [JsonPropertyName("request_type")]
    public string RequestType { get; set; } = string.Empty;

    [JsonPropertyName("external_ref_number")]
    public string ExternalRefNumber { get; set; } = string.Empty;
}
