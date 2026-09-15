using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Auth;

/// <summary>
/// Signature only uses plain types (User, strings) - no JWT-library types -
/// so this interface can live in Application while the real implementation
/// (JwtTokenService, using System.IdentityModel.Tokens.Jwt) lives in
/// Infrastructure. Same placement rule as everything else in this solution.
/// </summary>
public interface ITokenService
{
    /// <summary>
    /// channel is PORTAL or MOBILE - embedded as a "channel" claim, and is
    /// what ChannelBindingMiddleware later compares against the request's
    /// own X-Channel header on every subsequent call this token is used
    /// for. A token minted with channel=PORTAL is rejected outright if
    /// presented with X-Channel: MOBILE, even for the exact same user.
    /// </summary>
    IssuedToken GenerateToken(User user, IReadOnlyList<string> permissionCodes, string channel);

    /// <summary>
    /// For USSD/WhatsApp channel-service accounts - not a User row at all
    /// (see ChannelServiceAccount), so this is a separate method rather
    /// than forcing a fake User through GenerateToken above. channel here
    /// is always the service account's own channel (USSD/WHATSAPP), not
    /// caller-supplied - same channel-binding enforcement applies.
    /// </summary>
    IssuedToken GenerateChannelServiceToken(long serviceAccountId, string roleCode, IReadOnlyList<string> permissionCodes, string channel);
}

/// <summary>What AuthService hands back to the controller after a successful login.</summary>
public class IssuedToken
{
    public string Token { get; init; } = string.Empty;
    public DateTime ExpiresAtUtc { get; init; }
}
