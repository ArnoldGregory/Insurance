using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using InsurancePlatform.Application.Auth;
using InsurancePlatform.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace InsurancePlatform.Infrastructure.Auth;

/// <summary>
/// Builds and signs the JWT handed back to a client after a successful
/// login. Reads its signing key/issuer/audience/expiry from the "Jwt"
/// section of appsettings.json (the dev-only placeholder key we added
/// earlier). Separate from Api's JWT bearer setup, which only VALIDATES
/// tokens on incoming requests - this class only ever creates them.
/// </summary>
public class JwtTokenService : ITokenService
{
    private readonly string _key;
    private readonly string _issuer;
    private readonly string _audience;
    private readonly int _expiryMinutes;

    public JwtTokenService(IConfiguration configuration)
    {
        _key = configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("Jwt:Key is not configured in appsettings.json.");
        _issuer = configuration["Jwt:Issuer"] ?? string.Empty;
        _audience = configuration["Jwt:Audience"] ?? string.Empty;
        _expiryMinutes = int.TryParse(configuration["Jwt:ExpiryMinutes"], out var minutes) ? minutes : 60;
    }

    public IssuedToken GenerateToken(User user, IReadOnlyList<string> permissionCodes, string channel)
    {
        // ClaimTypes.NameIdentifier (user_id) is what identifies the caller
        // on every later request - not id_no, since usp_User_GetByIdNoForLogin
        // doesn't even return it (see User.cs's comment). ClaimTypes.Role
        // carries role_code (SA/AA/AG/SP/CL) for coarse role checks; the
        // "permission" claims (one per code) are what
        // [Authorize(Policy = PermissionCodes.X)] checks against. "channel"
        // is what ChannelBindingMiddleware checks against the request's own
        // X-Channel header. "actor_type"=USER is for symmetry with
        // GenerateChannelServiceToken's "actor_type"=CHANNEL_SERVICE -
        // lets anything reading claims generically tell the two kinds of
        // token apart without special-casing on role_code.
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new(ClaimTypes.Role, user.RoleCode),
            new("full_name", user.FullName),
            new("channel", channel),
            new("actor_type", "USER")
        };

        claims.AddRange(permissionCodes.Select(code => new Claim("permission", code)));

        return BuildToken(claims);
    }

    public IssuedToken GenerateChannelServiceToken(long serviceAccountId, string roleCode, IReadOnlyList<string> permissionCodes, string channel)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, serviceAccountId.ToString()),
            new(ClaimTypes.Role, roleCode),
            new("full_name", $"{channel} Channel Service"),
            new("channel", channel),
            new("actor_type", "CHANNEL_SERVICE")
        };

        claims.AddRange(permissionCodes.Select(code => new Claim("permission", code)));

        return BuildToken(claims);
    }

    private IssuedToken BuildToken(List<Claim> claims)
    {
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_expiryMinutes);

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_key));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new IssuedToken
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            ExpiresAtUtc = expiresAtUtc
        };
    }
}
