using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Options;

namespace InsurancePlatform.Infrastructure.Integrations.GovConnect;

/// <summary>
/// Two-step gateway, same shape as your legacy GetTaxpayer action: (1) GET
/// a Bearer token using Basic auth (ConsumerKey:SecretKey base64-encoded),
/// (2) POST {TaxpayerType:"KE", TaxpayerID:idNo} to the checker endpoint
/// with that token. Kept the one-retry-on-missing-fields behavior from the
/// legacy code (GovConnect apparently sometimes returns an incomplete
/// response on the first try) - everything else is a straight port to
/// System.Text.Json (matching the rest of this codebase, no new Newtonsoft
/// dependency needed) and to this project's IHttpClientFactory-pooled
/// HttpClient instead of a fresh `new HttpClient()` per call.
/// </summary>
public class GovConnectClient : ITaxpayerLookupClient
{
    private const string SuccessResponseCode = "30000";

    private readonly HttpClient _httpClient;
    private readonly GovConnectSettings _settings;
    private readonly ILoggerManager _logger;

    public GovConnectClient(HttpClient httpClient, IOptions<GovConnectSettings> settings, ILoggerManager logger)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<TaxpayerLookupResult?> LookupAsync(string idNo)
    {
        var accessToken = await GetAccessTokenAsync();
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return null;
        }

        var checkerResponse = await CallCheckerAsync(idNo, accessToken);

        if (!HasExpectedFields(checkerResponse))
        {
            _logger.LogWarn($"GovConnect checker response missing expected fields for id_no={idNo} - retrying once.");
            checkerResponse = await CallCheckerAsync(idNo, accessToken);
        }

        if (checkerResponse?.ResponseCode != SuccessResponseCode
            || string.IsNullOrWhiteSpace(checkerResponse.TaxpayerPIN)
            || string.IsNullOrWhiteSpace(checkerResponse.TaxpayerName))
        {
            _logger.LogInfo($"GovConnect - no taxpayer record for id_no={idNo} (ResponseCode={checkerResponse?.ResponseCode ?? "(none)"}).");
            return null;
        }

        return new TaxpayerLookupResult
        {
            Pin = checkerResponse.TaxpayerPIN,
            FullName = checkerResponse.TaxpayerName
        };
    }

    private async Task<string?> GetAccessTokenAsync()
    {
        var credentials = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{_settings.ConsumerKey}:{_settings.SecretKey}"));

        using var request = new HttpRequestMessage(HttpMethod.Get, $"{_settings.Url}/v1/token/generate?grant_type=client_credentials");

        // Set the header on this ONE request, not on the shared HttpClient.
        // AddHttpClient hands out a pooled/reused HttpClient instance (see
        // Program.cs), so mutating its DefaultRequestHeaders the way the
        // legacy code did would leak across every concurrent request using
        // that same pooled instance. A per-request header sidesteps the
        // problem entirely - the legacy code avoided it a different way, by
        // creating a brand-new HttpClient per call, which works but is the
        // exact pattern AddHttpClient exists to avoid (socket exhaustion
        // under load).
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);

        try
        {
            using var response = await _httpClient.SendAsync(request);
            var raw = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode || string.IsNullOrWhiteSpace(raw))
            {
                _logger.LogError($"GovConnect token endpoint returned HTTP {(int)response.StatusCode} or an empty body.");
                return null;
            }

            var token = JsonSerializer.Deserialize<GovConnectTokenResponse>(raw);
            return token?.AccessToken;
        }
        catch (Exception ex)
        {
            _logger.LogError("GovConnect - exception while requesting an access token.", ex);
            return null;
        }
    }

    private async Task<GovConnectCheckerResponse?> CallCheckerAsync(string idNo, string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{_settings.Url}/checker/v1/pin")
        {
            Content = JsonContent.Create(new GovConnectCheckerRequest
            {
                TaxpayerType = "KE",
                TaxpayerID = idNo.Trim().ToUpperInvariant()
            })
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        try
        {
            using var response = await _httpClient.SendAsync(request);
            var raw = await response.Content.ReadAsStringAsync();

            return string.IsNullOrWhiteSpace(raw) ? null : JsonSerializer.Deserialize<GovConnectCheckerResponse>(raw);
        }
        catch (Exception ex)
        {
            _logger.LogError($"GovConnect - exception while calling the checker endpoint for id_no={idNo}.", ex);
            return null;
        }
    }

    private static bool HasExpectedFields(GovConnectCheckerResponse? response) =>
        response is not null && !string.IsNullOrWhiteSpace(response.TaxpayerPIN) && !string.IsNullOrWhiteSpace(response.TaxpayerName);
}
