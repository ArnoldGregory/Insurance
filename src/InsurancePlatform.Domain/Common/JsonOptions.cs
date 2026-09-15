using System.Text.Json;

namespace InsurancePlatform.Domain.Common;

/// <summary>
/// Shared System.Text.Json settings for the handful of places this API
/// serializes/deserializes a nested JSON shape by hand (e.g. the
/// family_members_json column) rather than letting ASP.NET Core's own
/// request/response formatting handle it. CamelCase matches the naming
/// policy those built-in request/response bodies already use, so a
/// hand-serialized value round-trips through the same shape a caller
/// sees everywhere else in this API.
/// </summary>
public static class JsonOptions
{
    public static readonly JsonSerializerOptions CamelCase = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };
}
