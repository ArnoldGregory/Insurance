using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Options;

namespace InsurancePlatform.Infrastructure.Integrations.Daraja;

/// <summary>
/// Talks to Safaricom Daraja DIRECTLY, with no SCAPI message gateway in
/// between. Two steps, exactly as Daraja documents them:
///   1. GET  {BaseUrl}/oauth/v1/generate?grant_type=client_credentials
///      with Basic auth (base64 of consumerKey:consumerSecret) -> access_token
///   2. POST {BaseUrl}/mpesa/stkpush/v1/processrequest
///      with Bearer token and the Daraja request body. The Password field is
///      base64(shortcode + passkey + timestamp) - the same encoding SCAPI's
///      own RMPESAMANAGER applies when it proxies the call.
/// A successful push returns Daraja's ResponseCode "0" and a
/// CheckoutRequestID; that ID is what Daraja echoes back in the STK
/// callback, so MpesaCallbackController can resolve the payment by it.
/// </summary>
public class DarajaStkClient : IDarajaStkClient
{
    private readonly HttpClient _httpClient;
    private readonly DarajaSettings _settings;
    private readonly ILoggerManager _logger;

    public DarajaStkClient(HttpClient httpClient, IOptions<DarajaSettings> settings, ILoggerManager logger)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<DarajaStkResult> PushAsync(DarajaStkRequest request)
    {
        if (string.IsNullOrWhiteSpace(_settings.ConsumerKey)
            || string.IsNullOrWhiteSpace(_settings.ConsumerSecret)
            || string.IsNullOrWhiteSpace(_settings.PassKey)
            || string.IsNullOrWhiteSpace(_settings.BusinessShortCode))
        {
            return new DarajaStkResult
            {
                Success = false,
                Message = "M-Pesa Daraja is not configured (consumer key/secret, pass key or business short code missing)."
            };
        }

        var accessToken = await GetAccessTokenAsync();
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return new DarajaStkResult
            {
                Success = false,
                Message = "Could not obtain a Daraja access token - the M-Pesa gateway did not answer."
            };
        }

        var timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
        var shortCode = _settings.BusinessShortCode.Trim();
        var password = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{shortCode}{_settings.PassKey.Trim()}{timestamp}"));

        // Daraja rejects fractional amounts, so round to whole shillings.
        var amount = (int)Math.Round(request.Amount, 0, MidpointRounding.AwayFromZero);

        var body = new JsonObject
        {
            ["BusinessShortCode"] = shortCode,
            ["Password"] = password,
            ["Timestamp"] = timestamp,
            ["TransactionType"] = "CustomerPayBillOnline",
            ["Amount"] = amount,
            ["PartyA"] = request.PhoneNumber,
            ["PartyB"] = shortCode,
            ["PhoneNumber"] = request.PhoneNumber,
            ["CallBackURL"] = request.CallbackUrl,
            ["AccountReference"] = request.AccountReference,
            ["TransactionDesc"] = request.TransactionDescription
        };

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{_settings.BaseUrl.TrimEnd('/')}/mpesa/stkpush/v1/processrequest")
        {
            Content = JsonContent.Create(body)
        };
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        string raw;
        try
        {
            using var response = await _httpClient.SendAsync(httpRequest);
            raw = await response.Content.ReadAsStringAsync();
            _logger.LogInfo($"Daraja STK push response (HTTP {(int)response.StatusCode}): {raw}");

            if (!response.IsSuccessStatusCode)
            {
                return new DarajaStkResult
                {
                    Success = false,
                    Message = $"Daraja returned HTTP {(int)response.StatusCode}: {raw}"
                };
            }
        }
        catch (Exception ex)
        {
            _logger.LogError("Daraja - exception while calling the STK push endpoint.", ex);
            return new DarajaStkResult
            {
                Success = false,
                Message = "Could not reach the M-Pesa gateway - please try again shortly."
            };
        }

        JsonObject? parsed;
        try
        {
            parsed = JsonNode.Parse(raw)?.AsObject();
        }
        catch (JsonException ex)
        {
            _logger.LogError("Daraja - STK push response was not valid JSON.", ex);
            return new DarajaStkResult
            {
                Success = false,
                Message = "The M-Pesa gateway returned an unreadable response."
            };
        }

        if (parsed is null)
        {
            return new DarajaStkResult
            {
                Success = false,
                Message = "The M-Pesa gateway returned an empty response."
            };
        }

        var responseCode = parsed["ResponseCode"]?.ToString();
        var merchantRequestId = parsed["MerchantRequestID"]?.ToString();
        var checkoutRequestId = parsed["CheckoutRequestID"]?.ToString();
        var description = parsed["ResponseDescription"]?.ToString();
        var customerMessage = parsed["CustomerMessage"]?.ToString();

        // ResponseCode "0" is Daraja's "the prompt was accepted and sent to
        // the customer's phone". Anything else is a rejection - most often a
        // wrong short code/pass key combination, or a phone number that
        // Safaricom will not prompt.
        if (responseCode == "0")
        {
            return new DarajaStkResult
            {
                Success = true,
                Message = "Payment request sent. Kindly check your phone and enter your M-Pesa PIN to complete the payment.",
                MerchantRequestId = merchantRequestId,
                CheckoutRequestId = checkoutRequestId
            };
        }

        var detail = !string.IsNullOrWhiteSpace(customerMessage) ? customerMessage : description;
        if (string.IsNullOrWhiteSpace(detail))
        {
            detail = "The M-Pesa gateway rejected the request.";
        }

        return new DarajaStkResult
        {
            Success = false,
            Message = $"Daraja error {responseCode ?? "(none)"} (short code {shortCode}): {detail}",
            MerchantRequestId = merchantRequestId,
            CheckoutRequestId = checkoutRequestId
        };
    }

    private async Task<string?> GetAccessTokenAsync()
    {
        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_settings.ConsumerKey}:{_settings.ConsumerSecret}"));

        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"{_settings.BaseUrl.TrimEnd('/')}/oauth/v1/generate?grant_type=client_credentials");

        // Per-request header, not on the pooled HttpClient - see the same
        // note on GovConnectClient.
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);

        try
        {
            using var response = await _httpClient.SendAsync(request);
            var raw = await response.Content.ReadAsStringAsync();
            _logger.LogInfo($"Daraja token response (HTTP {(int)response.StatusCode}): {raw}");

            if (!response.IsSuccessStatusCode || string.IsNullOrWhiteSpace(raw))
            {
                _logger.LogError($"Daraja token endpoint returned HTTP {(int)response.StatusCode} or an empty body.");
                return null;
            }

            return JsonSerializer.Deserialize<DarajaTokenResponse>(raw)?.AccessToken;
        }
        catch (Exception ex)
        {
            _logger.LogError("Daraja - exception while requesting an access token.", ex);
            return null;
        }
    }
}

public class DarajaTokenResponse
{
    [System.Text.Json.Serialization.JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }
}
