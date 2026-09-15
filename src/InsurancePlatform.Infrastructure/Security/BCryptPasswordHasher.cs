using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Infrastructure.Security;

/// <summary>
/// The only class that references the BCrypt.Net-Next package directly.
/// Application (AuthService) depends on IPasswordHasher and gets this
/// injected at runtime - registered in Api's Program.cs.
/// </summary>
public class BCryptPasswordHasher : IPasswordHasher
{
    public string Hash(string plainPassword) => BCrypt.Net.BCrypt.HashPassword(plainPassword);

    public bool Verify(string plainPassword, string hash) => BCrypt.Net.BCrypt.Verify(plainPassword, hash);
}
