using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Options;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

namespace InsurancePlatform.Infrastructure.Integrations.Scapi;

public class ScapiGatewayClient : IScapiGatewayClient
{
    private readonly HttpClient _httpClient;
    private readonly ScapiSettings _settings;
    private readonly ILoggerManager _logger;

    public ScapiGatewayClient(HttpClient httpClient, IOptions<ScapiSettings> settings, ILoggerManager logger)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<JsonObject?> InvokeAsync(ScapiMessageRoute route, JsonObject messageBody)
    {
        var token = await GetTokenAsync();
        if (string.IsNullOrEmpty(token))
        {
            _logger.LogError($"SCAPI ref={route.ExternalRefNumber}: could not obtain a gateway token - call not sent.");
            return null;
        }

        var encodedToken = Convert.ToBase64String(Encoding.UTF8.GetBytes(token));

        var envelope = new ScapiRequestEnvelope
        {
            
            MessageValidation = new ScapiCredentials
            {
                ApiUser = "-",
                ApiPassword = "-",
                Token = encodedToken
            },
            MessageRoute = route,
            MessageBody = messageBody
        };

        //_logger.LogInfo($"requestTypeBody : {envelope.ToString()} ");
        _logger.LogInfo($"requestTypeBody : {JsonSerializer.Serialize(envelope)}");

        _logger.LogInfo($"SCAPI ref={route.ExternalRefNumber}: invoking interface={route.Interface}, request_type={route.RequestType}.");

string raw;

        try
        {
            using var response = await _httpClient.PostAsJsonAsync(_settings.Url, envelope);
            raw = await response.Content.ReadAsStringAsync();

            _logger.LogInfo($"SCAPI ref={route.ExternalRefNumber}: response: {raw}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"SCAPI ref={route.ExternalRefNumber}: gateway returned HTTP {(int)response.StatusCode}.");
                return null;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError($"SCAPI ref={route.ExternalRefNumber}: exception while sending to gateway.", ex);
            return null;
        }

        try
        {
            return JsonNode.Parse(raw)?.AsObject();
        }
        catch (JsonException ex)
        {
            _logger.LogError($"SCAPI ref={route.ExternalRefNumber}: response was not valid JSON.", ex);
            return null;
        }
    }

   
    private async Task<string?> GetTokenAsync()
    {
        var request = new ScapiTokenRequestEnvelope
        {
            MessageValidation = new ScapiCredentials
            {
                ApiUser = _settings.ApiUser,
                ApiPassword = _settings.ApiPassword
            },
            MessageRoute = new ScapiTokenRoute()
        };

        try
        {
            using var response = await _httpClient.PostAsJsonAsync(_settings.Url, request);
            var raw = await response.Content.ReadAsStringAsync();
            _logger.LogInfo($"SCAPI: token response: {raw}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"SCAPI: token request returned HTTP {(int)response.StatusCode}.");
                return null;
            }

            var parsed = JsonSerializer.Deserialize<ScapiTokenResponse>(raw);
            return parsed?.ErrorDesc?.Token;
        }
        catch (Exception ex)
        {
            _logger.LogError("SCAPI: exception while requesting gateway token.", ex);
            return null;
        }
    }
}
