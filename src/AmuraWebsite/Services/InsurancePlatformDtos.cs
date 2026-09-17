using System.Text.Json;
using System.Text.Json.Serialization;

namespace AmuraWebsite.Services;

public sealed class ApiEnvelope<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
}

public sealed class LoginResponseData
{
    public string? Token { get; set; }
}

public sealed class QuoteRequestResponseData
{
    // The platform's docs don't pin down whether this comes back as a
    // string or a number, so accept either and normalize to string.
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? Extra { get; set; }

    public string? QuoteRequestId =>
        Extra != null && Extra.TryGetValue("quoteRequestId", out var el)
            ? el.ToString()
            : null;

    // The platform's own human-readable reference (e.g. "MI-CECE76") —
    // this is what should actually be shown to the client, not the raw
    // numeric quoteRequestId.
    public string? RefNo =>
        Extra != null && Extra.TryGetValue("refNo", out var el)
            ? el.ToString()
            : null;
}

/// <summary>
/// What a successful platform submission gives back: the platform's
/// internal numeric id (useful for support/debugging) and its own
/// human-readable reference number (what the client should actually see).
/// </summary>
public sealed record PlatformSubmissionResult(string? QuoteRequestId, string? RefNo);
