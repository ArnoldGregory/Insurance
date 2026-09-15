using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using InsurancePlatform.Application.Integrations;

namespace InsurancePlatform.Infrastructure.Integrations.Scapi;


public class ScapiCredentials
{
    [JsonPropertyName("api_user")]
    public string ApiUser { get; set; } = string.Empty;

    [JsonPropertyName("api_password")]
    public string ApiPassword { get; set; } = string.Empty;

    [JsonPropertyName("token")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Token { get; set; }
}

public class ScapiTokenRoute
{
    [JsonPropertyName("interface")]
    public string Interface { get; set; } = "TOKEN";
}

public class ScapiTokenRequestEnvelope
{
    [JsonPropertyName("message_validation")]
    public ScapiCredentials MessageValidation { get; set; } = new();

    [JsonPropertyName("message_route")]
    public ScapiTokenRoute MessageRoute { get; set; } = new();
}

/// <summary>What the token call responds with - error_desc.token is what we need.</summary>
public class ScapiTokenResponse
{
    [JsonPropertyName("error_code")]
    public string? ErrorCode { get; set; }

    [JsonPropertyName("error_desc")]
    public ScapiTokenErrorDesc? ErrorDesc { get; set; }
}

public class ScapiTokenErrorDesc
{
    [JsonPropertyName("token")]
    public string? Token { get; set; }
}


public class ScapiRequestEnvelope
{
    [JsonPropertyName("message_validation")]
    public ScapiCredentials MessageValidation { get; set; } = new();

    [JsonPropertyName("message_route")]
    public ScapiMessageRoute MessageRoute { get; set; } = new();

    [JsonPropertyName("message_body")]
    public JsonObject MessageBody { get; set; } = new();
}
