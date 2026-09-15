using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using InsurancePlatform.Domain.Entities;
using InsurancePlatform.Infrastructure.Auth;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace InsurancePlatform.Tests;

public class JwtTokenServiceTests
{
    private const string TestKey = "a3f9c2d4b6e180a5d7c4f9b2e6d1a8c3f5b7e9d2c4a6f8b1d3e5c7a9b0d2f4e6";
    private const string Issuer = "InsurancePlatform.Api";
    private const string Audience = "InsurancePlatform.Clients";

    private static IConfiguration BuildConfig(int expiryMinutes = 45) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = TestKey,
                ["Jwt:Issuer"] = Issuer,
                ["Jwt:Audience"] = Audience,
                ["Jwt:ExpiryMinutes"] = expiryMinutes.ToString()
            })
            .Build();

    private static TokenValidationParameters BuildValidationParameters() =>
        new()
        {
            ValidateIssuer = true,
            ValidIssuer = Issuer,
            ValidateAudience = true,
            ValidAudience = Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(TestKey)),
            ValidateLifetime = true,
            RequireExpirationTime = true,
            ValidAlgorithms = [SecurityAlgorithms.HmacSha256]
        };

    private static ClaimsPrincipal ValidateAndRead(string token)
    {
        var handler = new JwtSecurityTokenHandler();
        return handler.ValidateToken(token, BuildValidationParameters(), out _);
    }

    [Fact]
    public void GenerateToken_RoundTripsThroughValidation()
    {
        var service = new JwtTokenService(BuildConfig());
        var user = new User { UserId = 99, RoleCode = "SA", FullName = "Test SuperAdmin" };
        var permissions = new List<string> { "CREATE_ADMIN", "MANAGE_CHANNELS" };

        var issued = service.GenerateToken(user, permissions, "PORTAL");

        Assert.False(string.IsNullOrWhiteSpace(issued.Token));
        Assert.True(issued.ExpiresAtUtc > DateTime.UtcNow.AddMinutes(44));

        var principal = ValidateAndRead(issued.Token);

        Assert.Equal("99", principal.FindFirstValue(ClaimTypes.NameIdentifier));
        Assert.Equal("SA", principal.FindFirstValue(ClaimTypes.Role));
        Assert.Equal("Test SuperAdmin", principal.FindFirstValue("full_name"));
        Assert.Equal("PORTAL", principal.FindFirstValue("channel"));
        Assert.Equal("USER", principal.FindFirstValue("actor_type"));
        Assert.Contains(principal.FindAll("permission"), c => c.Value == "CREATE_ADMIN");
        Assert.Contains(principal.FindAll("permission"), c => c.Value == "MANAGE_CHANNELS");
    }

    [Fact]
    public void GenerateToken_ExpiresWithinConfiguredWindow()
    {
        var service = new JwtTokenService(BuildConfig(expiryMinutes: 45));
        var user = new User { UserId = 1, RoleCode = "CL" };
        var before = DateTime.UtcNow.AddMinutes(45);

        var issued = service.GenerateToken(user, Array.Empty<string>(), "MOBILE");

        Assert.True(issued.ExpiresAtUtc <= before.AddMinutes(1));
        Assert.True(issued.ExpiresAtUtc > DateTime.UtcNow.AddMinutes(43));
    }

    [Fact]
    public void GenerateToken_SignedWithHs256Algorithm()
    {
        var service = new JwtTokenService(BuildConfig());
        var user = new User { UserId = 1, RoleCode = "SA" };

        var issued = service.GenerateToken(user, Array.Empty<string>(), "PORTAL");
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(issued.Token);

        Assert.Equal(SecurityAlgorithms.HmacSha256, jwt.Header.Alg);
    }

    [Fact]
    public void GenerateToken_RejectedWhenValidatedWithDifferentKey()
    {
        var service = new JwtTokenService(BuildConfig());
        var user = new User { UserId = 1, RoleCode = "SA" };
        var issued = service.GenerateToken(user, Array.Empty<string>(), "PORTAL");

        var wrongKeyParams = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                System.Text.Encoding.UTF8.GetBytes("b2d4e6f8a1c3e5b7d9f2a4c6e8b1d3f5a7c9e2b4d6f8a1c3e5b7d9f2a4c6e8b1d3f5")),
            ValidateIssuer = true,
            ValidIssuer = Issuer,
            ValidateAudience = true,
            ValidAudience = Audience,
            ValidateLifetime = true
        };

        var handler = new JwtSecurityTokenHandler();
        var ex = Assert.Throws<SecurityTokenSignatureKeyNotFoundException>(() =>
            handler.ValidateToken(issued.Token, wrongKeyParams, out _));
        Assert.NotNull(ex);
    }

    [Fact]
    public void GenerateChannelServiceToken_HasChannelServiceActorType()
    {
        var service = new JwtTokenService(BuildConfig());

        var issued = service.GenerateChannelServiceToken(42, "CS", ["MANAGE_CHANNELS"], "USSD");

        var principal = ValidateAndRead(issued.Token);
        Assert.Equal("42", principal.FindFirstValue(ClaimTypes.NameIdentifier));
        Assert.Equal("USSD", principal.FindFirstValue("channel"));
        Assert.Equal("CHANNEL_SERVICE", principal.FindFirstValue("actor_type"));
        Assert.Contains(principal.FindAll("permission"), c => c.Value == "MANAGE_CHANNELS");
    }
}