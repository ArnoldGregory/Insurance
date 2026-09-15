using System.Text;
using System.Text.Json;

namespace InsurancePlatform.AdminPortal.Services;

/// <summary>
/// Reads the claims out of a JWT's payload segment WITHOUT validating its
/// signature or expiry - safe here specifically because this app never
/// accepts a token from anywhere except its own direct call to
/// InsurancePlatform.Api's /api/auth/verify-otp (see AccountController),
/// over a connection this app itself made. This app is never handed a
/// token by some other, untrusted caller the way InsurancePlatform.Api's
/// own bearer-token validation (AddJwtBearer in that project's Program.cs)
/// has to be - it's just reading back the claims from a token it, itself,
/// received seconds ago. Exists so AccountController can pull user_id/
/// role_code/full_name straight out of the token it already has instead of
/// making a second round-trip to GET /api/auth/me for the same data.
/// </summary>
public static class JwtClaimsReader
{
    /// <summary>Single-valued claims (user_id, role, full_name, channel, etc.) - last-one-wins is fine for these, none of them repeat. See ReadPermissions for the one claim ("permission") that does repeat.</summary>
    public static IReadOnlyDictionary<string, string> ReadClaims(string jwt)
    {
        using var document = ParsePayload(jwt);
        var claims = new Dictionary<string, string>();

        foreach (var property in document.RootElement.EnumerateObject())
        {
            claims[property.Name] = property.Value.ValueKind == JsonValueKind.String
                ? property.Value.GetString() ?? string.Empty
                : property.Value.GetRawText();
        }

        return claims;
    }

    /// <summary>
    /// JwtTokenService adds one "permission" claim per PermissionCode the
    /// caller's role holds - the standard JWT library collapses multiple
    /// same-named claims into a single JSON array in the token payload
    /// (not repeated keys, which plain JSON can't represent unambiguously),
    /// so this reads it as an array. Falls back to treating it as one
    /// value if a role somehow has exactly one permission (some JWT
    /// libraries emit a bare string instead of a one-element array in that
    /// case), and to an empty list if the claim is missing entirely.
    /// </summary>
    public static List<string> ReadPermissions(string jwt)
    {
        using var document = ParsePayload(jwt);

        if (!document.RootElement.TryGetProperty("permission", out var permissionElement))
        {
            return new List<string>();
        }

        return permissionElement.ValueKind switch
        {
            JsonValueKind.Array => permissionElement.EnumerateArray().Select(e => e.GetString() ?? string.Empty).ToList(),
            JsonValueKind.String => new List<string> { permissionElement.GetString() ?? string.Empty },
            _ => new List<string>()
        };
    }

    private static JsonDocument ParsePayload(string jwt)
    {
        var parts = jwt.Split('.');
        if (parts.Length != 3)
        {
            throw new FormatException("Not a well-formed JWT (expected 3 dot-separated segments).");
        }

        var payloadJson = Encoding.UTF8.GetString(Base64UrlDecode(parts[1]));
        return JsonDocument.Parse(payloadJson);
    }

    private static byte[] Base64UrlDecode(string input)
    {
        var padded = input.Replace('-', '+').Replace('_', '/');
        padded = (padded.Length % 4) switch
        {
            2 => padded + "==",
            3 => padded + "=",
            _ => padded
        };

        return Convert.FromBase64String(padded);
    }
}
