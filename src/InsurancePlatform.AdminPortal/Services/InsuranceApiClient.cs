using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using InsurancePlatform.AdminPortal.Models;
using Microsoft.AspNetCore.Http;

namespace InsurancePlatform.AdminPortal.Services;

/// <summary>
/// The one gateway this whole portal uses to talk to InsurancePlatform.Api
/// - every controller goes through this instead of holding its own
/// HttpClient, so the auth-header/channel-header/envelope-parsing logic
/// lives in exactly one place. Login/VerifyOtp are anonymous (no token
/// exists yet - that's the whole point of those two calls). GetAsync/
/// PostAsync/PutAsync are generic helpers for every authenticated screen
/// (including MenuViewComponent's GET /api/menus/mine call, and every
/// future business-data screen), and read the caller's token off the
/// current signed-in user's "access_token" claim automatically - see
/// AccountController.VerifyOtp for where that claim gets set.
/// </summary>
public interface IInsuranceApiClient
{
    Task<ApiResponse<object?>> LoginAsync(string idNo, string password);
    Task<ApiResponse<VerifyOtpData>> VerifyOtpAsync(string idNo, string otpCode);
    Task<ApiResponse<T>> GetAsync<T>(string path);
    Task<ApiResponse<T>> PostAsync<T>(string path, object body);
    Task<ApiResponse<T>> PutAsync<T>(string path, object body);
    Task<ApiResponse<T>> DeleteAsync<T>(string path);

    /// <summary>
    /// Multipart/form-data POST - the one thing in this app that needs to
    /// forward a real uploaded file (quote-offer documents) instead of
    /// sending JSON. `file` is optional (some offers have no document yet);
    /// `fields` are the other form fields (UnderwriterId, PremiumAmount...)
    /// as plain strings - the API's own [FromForm] model binder converts
    /// them back to their real types, same as it would for any HTML form
    /// post.
    /// </summary>
    Task<ApiResponse<T>> PostFormAsync<T>(string path, IFormFile? file, string fileFieldName, IDictionary<string, string> fields);

    /// <summary>Same as PostFormAsync, but PUT - for editing an existing quote offer.</summary>
    Task<ApiResponse<T>> PutFormAsync<T>(string path, IFormFile? file, string fileFieldName, IDictionary<string, string> fields);

    /// <summary>
    /// Multipart/form-data POST that can carry MORE THAN ONE file at once -
    /// the batch add/edit-offers endpoints bind a List&lt;T&gt; from indexed
    /// field names (Offers[0].UnderwriterId, Offers[0].Document, Offers[1].
    /// UnderwriterId, ...), and each row can have its own optional document.
    /// `files` maps a field name (e.g. "Offers[0].Document") to the
    /// IFormFile for that specific row - simply omit an index's key
    /// entirely if that row has no document. `fields` holds every other
    /// (non-file) indexed field, same convention as PostFormAsync's fields.
    /// </summary>
    Task<ApiResponse<T>> PostMultiFormAsync<T>(string path, IDictionary<string, IFormFile> files, IDictionary<string, string> fields);

    /// <summary>Same as PostMultiFormAsync, but PUT - for the batch-edit-offers endpoint.</summary>
    Task<ApiResponse<T>> PutMultiFormAsync<T>(string path, IDictionary<string, IFormFile> files, IDictionary<string, string> fields);

    /// <summary>
    /// The API's own base URL (e.g. https://localhost:5044) - exposed so a
    /// view can turn a document_path like "/uploads/quote-offers/xxx.pdf"
    /// (relative to the API, not this portal - they're different origins)
    /// into a real clickable link. Read-only passthrough of the HttpClient's
    /// own BaseAddress, which is already configured from InsuranceApi:BaseUrl
    /// in Program.cs - not a second place to configure the same value.
    /// </summary>
    Uri? ApiBaseAddress { get; }

    /// <summary>
    /// Downloads a binary response (e.g. GET /api/quoterequests/{id}/offers/
    /// {offerId}/document) with the signed-in user's auth attached, handing
    /// back the raw content stream + metadata for proxy-streaming to the
    /// browser. Null when the API answered non-success. Caller owns the stream.
    /// </summary>
    Task<ApiFileStream?> GetStreamAsync(string path);
}

/// <summary>Metadata + content of a successful binary (file download) API response - returned by IInsuranceApiClient.GetStreamAsync.</summary>
public class ApiFileStream
{
    public required Stream Content { get; init; }
    public string? ContentType { get; init; }
    public string? FileName { get; init; }
    public long? ContentLength { get; init; }
}

public class InsuranceApiClient : IInsuranceApiClient
{
    // Every token this app ever mints is minted with Channel="PORTAL" (see
    // AccountController.VerifyOtp) - ChannelBindingMiddleware on the API
    // side rejects any request whose X-Channel header doesn't match that
    // exactly, so every authenticated call this client makes has to send
    // it back.
    private const string Channel = "PORTAL";

    // The claim type AccountController stashes the raw JWT under inside
    // the encrypted auth cookie - see its SignInAsync call.
    public const string AccessTokenClaimType = "access_token";

    private readonly HttpClient _httpClient;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private static readonly JsonSerializerOptions ResponseJsonOptions = new() { PropertyNameCaseInsensitive = true };

    public InsuranceApiClient(HttpClient httpClient, IHttpContextAccessor httpContextAccessor)
    {
        _httpClient = httpClient;
        _httpContextAccessor = httpContextAccessor;
    }

    public Uri? ApiBaseAddress => _httpClient.BaseAddress;

    public async Task<ApiResponse<object?>> LoginAsync(string idNo, string password)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/auth/login", new { idNo, password });
        return await ReadResponseAsync<object?>(response);
    }

    public async Task<ApiResponse<VerifyOtpData>> VerifyOtpAsync(string idNo, string otpCode)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/auth/verify-otp", new { idNo, otpCode, channel = Channel });
        return await ReadResponseAsync<VerifyOtpData>(response);
    }

    public Task<ApiResponse<T>> GetAsync<T>(string path) => SendAuthenticatedAsync<T>(HttpMethod.Get, path, null);

    public Task<ApiResponse<T>> PostAsync<T>(string path, object body) => SendAuthenticatedAsync<T>(HttpMethod.Post, path, body);

    public Task<ApiResponse<T>> PutAsync<T>(string path, object body) => SendAuthenticatedAsync<T>(HttpMethod.Put, path, body);

    public Task<ApiResponse<T>> DeleteAsync<T>(string path) => SendAuthenticatedAsync<T>(HttpMethod.Delete, path, null);

    public Task<ApiResponse<T>> PostFormAsync<T>(string path, IFormFile? file, string fileFieldName, IDictionary<string, string> fields)
        => SendMultipartAsync<T>(HttpMethod.Post, path, file, fileFieldName, fields);

    public Task<ApiResponse<T>> PutFormAsync<T>(string path, IFormFile? file, string fileFieldName, IDictionary<string, string> fields)
        => SendMultipartAsync<T>(HttpMethod.Put, path, file, fileFieldName, fields);

    public Task<ApiResponse<T>> PostMultiFormAsync<T>(string path, IDictionary<string, IFormFile> files, IDictionary<string, string> fields)
        => SendMultipartMultiAsync<T>(HttpMethod.Post, path, files, fields);

    public Task<ApiResponse<T>> PutMultiFormAsync<T>(string path, IDictionary<string, IFormFile> files, IDictionary<string, string> fields)
        => SendMultipartMultiAsync<T>(HttpMethod.Put, path, files, fields);

    /// <summary>
    /// Raw binary GET with auth - unlike the ApiResponse<T> methods, a
    /// non-success status returns null instead of a parsed envelope, since
    /// there's no JSON body to parse for a file endpoint. The response
    /// (and its stream) must be disposed by the caller.
    /// </summary>
    public async Task<ApiFileStream?> GetStreamAsync(string path)
    {
        var token = _httpContextAccessor.HttpContext?.User.FindFirst(AccessTokenClaimType)?.Value;

        if (string.IsNullOrEmpty(token))
        {
            throw new InvalidOperationException(
                "No signed-in user with an access_token claim - GetStreamAsync requires an authenticated request.");
        }

        using var request = new HttpRequestMessage(HttpMethod.Get, path);
        AttachAuthHeaders(request, token);

        var response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);

        if (!response.IsSuccessStatusCode)
        {
            response.Dispose();
            return null;
        }

        string? fileName = null;
        if (response.Content.Headers.ContentDisposition?.FileName is { Length: > 0 } cdFileName)
        {
            fileName = cdFileName.Trim('"');
        }

        return new ApiFileStream
        {
            Content = await response.Content.ReadAsStreamAsync(),
            ContentType = response.Content.Headers.ContentType?.MediaType,
            FileName = fileName,
            ContentLength = response.Content.Headers.ContentLength
        };
    }

    /// <summary>Same shape/reasoning as SendMultipartAsync below, just with an arbitrary number of named file parts instead of exactly one.</summary>
    private async Task<ApiResponse<T>> SendMultipartMultiAsync<T>(HttpMethod method, string path, IDictionary<string, IFormFile> files, IDictionary<string, string> fields)
    {
        var token = _httpContextAccessor.HttpContext?.User.FindFirst(AccessTokenClaimType)?.Value;

        if (string.IsNullOrEmpty(token))
        {
            throw new InvalidOperationException(
                "No signed-in user with an access_token claim - PostMultiFormAsync/PutMultiFormAsync require an authenticated request.");
        }

        using var request = new HttpRequestMessage(method, path);
        AttachAuthHeaders(request, token);

        var content = new MultipartFormDataContent();
        foreach (var field in fields)
        {
            content.Add(new StringContent(field.Value), field.Key);
        }

        foreach (var file in files)
        {
            if (file.Value is null || file.Value.Length == 0)
            {
                continue;
            }

            var fileContent = new StreamContent(file.Value.OpenReadStream());
            fileContent.Headers.ContentType = new MediaTypeHeaderValue(
                string.IsNullOrEmpty(file.Value.ContentType) ? "application/octet-stream" : file.Value.ContentType);
            content.Add(fileContent, file.Key, file.Value.FileName);
        }

        request.Content = content;

        var response = await _httpClient.SendAsync(request);
        return await ReadResponseAsync<T>(response);
    }

    private async Task<ApiResponse<T>> SendMultipartAsync<T>(HttpMethod method, string path, IFormFile? file, string fileFieldName, IDictionary<string, string> fields)
    {
        var token = _httpContextAccessor.HttpContext?.User.FindFirst(AccessTokenClaimType)?.Value;

        if (string.IsNullOrEmpty(token))
        {
            throw new InvalidOperationException(
                "No signed-in user with an access_token claim - PostFormAsync/PutFormAsync require an authenticated request.");
        }

        using var request = new HttpRequestMessage(method, path);
        AttachAuthHeaders(request, token);

        var content = new MultipartFormDataContent();
        foreach (var field in fields)
        {
            content.Add(new StringContent(field.Value), field.Key);
        }

        if (file is not null && file.Length > 0)
        {
            // OpenReadStream() (not CopyToAsync into a buffer) - the file
            // streams straight through to the real API as this request
            // sends, instead of being fully buffered in AdminPortal's memory
            // first. Disposed automatically when `content`/`request` are.
            var fileContent = new StreamContent(file.OpenReadStream());
            fileContent.Headers.ContentType = new MediaTypeHeaderValue(
                string.IsNullOrEmpty(file.ContentType) ? "application/octet-stream" : file.ContentType);
            content.Add(fileContent, fileFieldName, file.FileName);
        }

        request.Content = content;

        var response = await _httpClient.SendAsync(request);
        return await ReadResponseAsync<T>(response);
    }

    private async Task<ApiResponse<T>> SendAuthenticatedAsync<T>(HttpMethod method, string path, object? body)
    {
        var token = _httpContextAccessor.HttpContext?.User.FindFirst(AccessTokenClaimType)?.Value;

        if (string.IsNullOrEmpty(token))
        {
            throw new InvalidOperationException(
                "No signed-in user with an access_token claim - GetAsync/PostAsync/PutAsync require an authenticated request. " +
                "Use LoginAsync/VerifyOtpAsync directly for the anonymous login handshake instead.");
        }

        using var request = new HttpRequestMessage(method, path);
        AttachAuthHeaders(request, token);

        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        var response = await _httpClient.SendAsync(request);
        return await ReadResponseAsync<T>(response);
    }

    private static void AttachAuthHeaders(HttpRequestMessage request, string token)
    {
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.Add("X-Channel", Channel);
    }

    // Every InsurancePlatform.Api controller returns HTTP 200 with
    // Success=false for an ordinary business-rule failure (wrong password,
    // expired OTP, "not found", etc.) - see ApiResponse<T>'s doc comment on
    // the API side. A non-2xx status here means something more fundamental
    // (a genuine 401/403 from [Authorize]/ChannelBindingMiddleware, a 500
    // from ExceptionHandlingMiddleware) - those still return the SAME
    // envelope shape, so this always tries to parse it first and only
    // falls back to a synthetic failure if the body isn't valid JSON at
    // all (e.g. the API is completely unreachable, or a proxy/gateway
    // error page came back instead).
    private static async Task<ApiResponse<T>> ReadResponseAsync<T>(HttpResponseMessage response)
    {
        var raw = await response.Content.ReadAsStringAsync();

        if (string.IsNullOrWhiteSpace(raw))
        {
            return new ApiResponse<T> { Success = false, Message = $"Empty response from the API ({(int)response.StatusCode} {response.StatusCode})." };
        }

        try
        {
            var parsed = JsonSerializer.Deserialize<ApiResponse<T>>(raw, ResponseJsonOptions);
            return parsed ?? new ApiResponse<T> { Success = false, Message = "Unrecognized response from the API." };
        }
        catch (JsonException)
        {
            return new ApiResponse<T> { Success = false, Message = $"Unrecognized response from the API ({(int)response.StatusCode} {response.StatusCode})." };
        }
    }
}
