using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;

namespace AmuraWebsite.Services;

public sealed class InsurancePlatformClient : IInsurancePlatformClient
{
    private readonly HttpClient _http;
    private readonly InsurancePlatformOptions _options;
    private readonly PlatformTokenCache _tokenCache;
    private readonly ILogger<InsurancePlatformClient> _logger;

    private static readonly TimeSpan AssumedTokenLifetime = TimeSpan.FromMinutes(45);

    private static readonly System.Text.Json.JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public InsurancePlatformClient(
        HttpClient http,
        IOptions<InsurancePlatformOptions> options,
        PlatformTokenCache tokenCache,
        ILogger<InsurancePlatformClient> logger)
    {
        _http = http;
        _options = options.Value;
        _tokenCache = tokenCache;
        _logger = logger;
    }

    public bool IsConfigured => _options.IsConfigured;

    public Task<PlatformSubmissionResult?> SubmitMedicalIndividualAsync(
        string clientName, DateTime clientDob, string idNo, string email, string phone,
        IReadOnlyList<(string Relationship, string FullName, DateTime DateOfBirth)> familyMembers,
        CancellationToken ct = default)
    {
        var payload = new
        {
            clientId = (int?)null,
            channel = "WEBSITE",
            clientName,
            clientDob = clientDob.ToString("yyyy-MM-dd"),
            familyMembers = familyMembers.Select(m => new
            {
                relationship = m.Relationship,
                fullName = m.FullName,
                dateOfBirth = m.DateOfBirth.ToString("yyyy-MM-dd")
            }),
            idNo,
            email,
            phone
        };
        return PostQuoteRequestAsync("/api/quoterequests/medical-individual", payload, ct);
    }

    public Task<PlatformSubmissionResult?> SubmitMedicalCorporateAsync(
        string companyName, string phone, string email,
        string idNo,
        CancellationToken ct = default)
    {
        var payload = new
        {
            clientId = (int?)null,
            channel = "WEBSITE",
            companyName,
            phone,
            email,
            idNo
        };
        return PostQuoteRequestAsync("/api/quoterequests/medical-corporate", payload, ct);
    }

    public Task<PlatformSubmissionResult?> SubmitProfessionalIndemnityAsync(
        string clientOrCompanyName, string phone, string email, string profession,
        string idNo,
        CancellationToken ct = default)
    {
        var payload = new
        {
            clientId = (int?)null,
            channel = "WEBSITE",
            clientOrCompanyName,
            phone,
            email,
            profession,
            idNo
        };
        return PostQuoteRequestAsync("/api/quoterequests/professional-indemnity", payload, ct);
    }

    public Task<PlatformSubmissionResult?> SubmitTravelAsync(
        string clientName, DateTime dob, string? kraPin, string destination,
        DateTime travelDateFrom, DateTime travelDateTo, bool travellingWithFamily, string tripType,
        string idNo, string email,
        CancellationToken ct = default)
    {
        var payload = new
        {
            clientId = (int?)null,
            channel = "WEBSITE",
            clientName,
            dob = dob.ToString("yyyy-MM-dd"),
            kraPin = kraPin ?? "",
            destination,
            travelDateFrom = travelDateFrom.ToString("yyyy-MM-ddTHH:mm:ss"),
            travelDateTo = travelDateTo.ToString("yyyy-MM-ddTHH:mm:ss"),
            travellingWithFamily,
            tripType,
            idNo,
            email
        };
        return PostQuoteRequestAsync("/api/quoterequests/travel", payload, ct);
    }

    public Task<PlatformSubmissionResult?> SubmitDomesticAsync(
      string detailsJson,
      string idNo,
      string email,
      CancellationToken ct = default)
    {
        var payload = new
        {
            clientId = (int?)null,
            channel = "WEBSITE",
            idNo = idNo,
            email = email,
            detailsJson = detailsJson
        };
        return PostQuoteRequestAsync("/api/quoterequests/domestic", payload, ct);
    }

    private async Task<PlatformSubmissionResult?> PostQuoteRequestAsync(string path, object payload, CancellationToken ct)
    {
        if (!IsConfigured)
        {
            return null;
        }

        var token = await EnsureTokenAsync(ct);
        if (token is null)
        {
            return null;
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, path)
            {
                Content = JsonContent.Create(payload)
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Add("X-Channel", "WEBSITE_GUEST");

            var payloadJson = System.Text.Json.JsonSerializer.Serialize(payload);
            _logger.LogInformation("Sending to {Path}: {Payload}", path, payloadJson);

            using var response = await _http.SendAsync(request, ct);

            if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            {
                _tokenCache.Clear();
                _logger.LogWarning("Insurance Platform API returned 401 on {Path}; token cleared.", path);
                return null;
            }

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("Insurance Platform API {Path} returned {Status}: {Body}", path, response.StatusCode, errorBody);
                return null;
            }

            var envelope = await response.Content.ReadFromJsonAsync<ApiEnvelope<QuoteRequestResponseData>>(JsonOptions, ct);
            if (envelope is { Success: true } && envelope.Data?.QuoteRequestId is { } id)
            {
                return new PlatformSubmissionResult(id, envelope.Data.RefNo);
            }

            _logger.LogWarning("Insurance Platform API {Path} responded without a usable quoteRequestId.", path);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Insurance Platform API call to {Path} failed.", path);
            return null;
        }
    }

    private async Task<string?> EnsureTokenAsync(CancellationToken ct)
    {
        if (_tokenCache.HasValidToken)
        {
            return _tokenCache.Token;
        }

        using var releaser = await _tokenCache.LockAsync(ct);

        if (_tokenCache.HasValidToken)
        {
            return _tokenCache.Token;
        }

        try
        {
            var loginPayload = new { channel = "WEBSITE_GUEST", apiKey = _options.WebsiteGuestApiKey };
            using var response = await _http.PostAsJsonAsync("/api/auth/channel-login", loginPayload, ct);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Insurance Platform channel-login returned {Status}.", response.StatusCode);
                return null;
            }

            var envelope = await response.Content.ReadFromJsonAsync<ApiEnvelope<LoginResponseData>>(JsonOptions, ct);
            if (envelope is { Success: true } && !string.IsNullOrEmpty(envelope.Data?.Token))
            {
                _tokenCache.SetToken(envelope.Data.Token, AssumedTokenLifetime);
                return envelope.Data.Token;
            }

            _logger.LogWarning("Insurance Platform channel-login succeeded but returned no token.");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Insurance Platform channel-login failed.");
            return null;
        }
    }
}