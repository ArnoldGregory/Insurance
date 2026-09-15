using System.Text.Json.Nodes;

namespace InsurancePlatform.Application.Integrations;

public interface IScapiGatewayClient
{
    Task<JsonObject?> InvokeAsync(ScapiMessageRoute route, JsonObject messageBody);
}
