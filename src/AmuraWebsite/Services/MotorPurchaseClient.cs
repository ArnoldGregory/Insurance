using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace AmuraWebsite.Services;

public sealed class MotorPurchaseClient : IMotorPurchaseClient
{
    private readonly HttpClient _http;
    private readonly InsurancePlatformOptions _options;
    private readonly PlatformTokenCache _tokenCache;
    private readonly ILogger<MotorPurchaseClient> _logger;

    private static readonly TimeSpan AssumedTokenLifetime = TimeSpan.FromMinutes(45);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public MotorPurchaseClient(
        HttpClient http,
        IOptions<InsurancePlatformOptions> options,
        PlatformTokenCache tokenCache,
        ILogger<MotorPurchaseClient> logger)
    {
        _http = http;
        _options = options.Value;
        _tokenCache = tokenCache;
        _logger = logger;
    }

    public bool IsConfigured => _options.IsConfigured;

    public async Task<List<VehicleClassDto>?> GetVehicleClassesAsync(CancellationToken ct = default)
    {
        var data = await GetAsync<List<VehicleClassDto>>("/api/products/motor-vehicle-classes", ct);
        return data;
    }

    public async Task<List<PeriodDto>?> GetPeriodsAsync(CancellationToken ct = default)
    {
        var data = await GetAsync<List<PeriodDto>>("/api/products/periods", ct);
        return data;
    }

    public async Task<int?> GetMotorProductIdAsync(CancellationToken ct = default)
    {
        var products = await GetAsync<List<ProductDto>>("/api/products", ct);
        // The motor product's exact code isn't confirmed from the Postman
        // examples we have — match on anything containing "MOTOR" as the
        // most defensive reasonable guess. If this returns null, the
        // caller should surface a clear error rather than guess further.
        return products?.FirstOrDefault(p => p.Code.Contains("MOTOR", StringComparison.OrdinalIgnoreCase))?.ProductId;
    }

    public async Task<List<TpoPriceOptionDto>?> GetTpoPricingAsync(
        int vehicleClassId, int periodId, int carryCapacity, CancellationToken ct = default)
    {
        var path = $"/api/pricing/tpo?vehicleClassId={vehicleClassId}&periodId={periodId}&carryCapacity={carryCapacity}";
        return await GetAsync<List<TpoPriceOptionDto>>(path, ct);
    }

    public async Task<ComprehensiveQuoteResponse?> GetComprehensiveCompareAsync(
        decimal vehicleValue, CancellationToken ct = default)
    {
        var path = $"/api/pricing/comprehensive/compare?vehicleValue={vehicleValue}";
        return await GetAsync<ComprehensiveQuoteResponse>(path, ct);
    }

    public async Task<ResolveClientResponseData?> ResolveClientAsync(string idNo, CancellationToken ct = default)
    {
        return await GetAsync<ResolveClientResponseData>($"/api/clients/resolve/{Uri.EscapeDataString(idNo)}", ct);
    }

    public async Task<int?> CreateClientAsync(
        string idNo, string fullName, DateTime dob, string email, string phone,
        string? address, string? kraPin, CancellationToken ct = default)
    {
        var payload = new
        {
            idNo,
            fullName,
            dob = dob.ToString("yyyy-MM-dd"),
            email,
            phone,
            address,
            kraPin,
            registrationChannel = "WEBSITE"
        };
        var data = await PostAsync<CreateClientResponseData>("/api/clients", payload, ct);
        return data?.ClientId;
    }

    public async Task<int?> RegisterVehicleAsync(
        int clientId, string make, string model, string regNo, string chassisNo, string engineNo,
        int yearOfManufacture, string vehicleType, string bodyType, string fuelType,
        string cubicCapacity, string color, string logbook, CancellationToken ct = default)
    {
        var payload = new
        {
            make,
            model,
            regNo,
            chassisNo,
            engineNo,
            yearOfManufacture,
            vehicleType,
            bodyType,
            fuelType,
            cubicCapacity,
            color,
            logbook
        };
        var data = await PostAsync<RegisterVehicleResponseData>($"/api/clients/{clientId}/vehicles", payload, ct);
        return data?.VehicleId;
    }

    public async Task<CreatePurchaseResponseData?> CreatePurchaseAsync(
        int productId, int clientId, int underwriterId, decimal premiumAmount, int periodId,
        DateTime startDate, int vehicleId, int licensedToCarry, CancellationToken ct = default)
    {
        var payload = new
        {
            productId,
            clientId,
            underwriterId,
            premiumAmount,
            periodId,
            startDate = startDate.ToString("yyyy-MM-dd"),
            vehicleId,
            licensedToCarry,
            channel = "WEBSITE"
        };
        return await PostAsync<CreatePurchaseResponseData>("/api/purchases", payload, ct);
    }

    public async Task<CreatePurchaseResponseData?> CreateComprehensivePurchaseAsync(
        int productId, int clientId, int underwriterId, decimal premiumAmount, int periodId,
        DateTime startDate, int vehicleId, decimal vehicleValue, CancellationToken ct = default)
    {
        var payload = new
        {
            productId,
            clientId,
            underwriterId,
            quoteOfferId = (int?)null,
            premiumAmount,
            periodId,
            startDate = startDate.ToString("yyyy-MM-dd"),
            policyNumber = (string?)null,
            vehicleId,
            vehicleValue,
            tonnage = (decimal?)null,
            licensedToCarry = (int?)null,
            antiTheft = (bool?)null,
            risk = "COMPREHENSIVE",
            snapshotAmount = (decimal?)null,
            channel = "WEBSITE"
        };
        return await PostAsync<CreatePurchaseResponseData>("/api/purchases", payload, ct);
    }

    public async Task<StkPushResponseData?> InitiatePaymentAsync(
        int purchaseId, decimal amount, string phoneNumber, string accountReference, CancellationToken ct = default)
    {
        var payload = new
        {
            purchaseId,
            amount,
            phoneNumber,
            accountReference
        };
        return await PostAsync<StkPushResponseData>("/api/payments/stk-push", payload, ct);
    }

    // ---- shared plumbing ----

    private async Task<T?> GetAsync<T>(string path, CancellationToken ct) where T : class
    {
        if (!IsConfigured) return null;
        var token = await EnsureTokenAsync(ct);
        if (token is null) return null;

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, path);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Add("X-Channel", "WEBSITE_GUEST");

            using var response = await _http.SendAsync(request, ct);
            if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            {
                _tokenCache.Clear();
                _logger.LogWarning("Motor GET {Path} returned 401; token cleared.", path);
                return null;
            }
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Motor GET {Path} returned {Status}.", path, response.StatusCode);
                return null;
            }

            var envelope = await response.Content.ReadFromJsonAsync<ApiEnvelope<T>>(JsonOptions, ct);
            if (envelope is { Success: true })
            {
                return envelope.Data;
            }
            _logger.LogWarning("Motor GET {Path} responded success=false.", path);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Motor GET {Path} failed.", path);
            return null;
        }
    }

    private async Task<T?> PostAsync<T>(string path, object payload, CancellationToken ct) where T : class
    {
        if (!IsConfigured) return null;
        var token = await EnsureTokenAsync(ct);
        if (token is null) return null;

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, path)
            {
                Content = JsonContent.Create(payload)
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Add("X-Channel", "WEBSITE_GUEST");

            using var response = await _http.SendAsync(request, ct);
            if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            {
                _tokenCache.Clear();
                _logger.LogWarning("Motor POST {Path} returned 401; token cleared.", path);
                return null;
            }
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("Motor POST {Path} returned {Status}: {Body}", path, response.StatusCode, body);
                return null;
            }

            var envelope = await response.Content.ReadFromJsonAsync<ApiEnvelope<T>>(JsonOptions, ct);
            if (envelope is { Success: true })
            {
                return envelope.Data;
            }
            _logger.LogWarning("Motor POST {Path} responded success=false: {Message}", path, envelope?.Message);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Motor POST {Path} failed.", path);
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
            if (!response.IsSuccessStatusCode) return null;

            var envelope = await response.Content.ReadFromJsonAsync<ApiEnvelope<LoginResponseData>>(JsonOptions, ct);
            if (envelope is { Success: true } && !string.IsNullOrEmpty(envelope.Data?.Token))
            {
                _tokenCache.SetToken(envelope.Data.Token, AssumedTokenLifetime);
                return envelope.Data.Token;
            }
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Motor channel-login failed.");
            return null;
        }
    }
}
