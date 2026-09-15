namespace InsurancePlatform.Domain.Common;

/// <summary>
/// Same placement logic as ILoggerManager: the signature here is just plain
/// strings and a bool - no BCrypt types - so Application can depend on this
/// interface without needing to know BCrypt exists. The real implementation
/// (BCryptPasswordHasher, using the BCrypt.Net-Next package) lives in
/// Infrastructure.
/// </summary>
public interface IPasswordHasher
{
    string Hash(string plainPassword);

    bool Verify(string plainPassword, string hash);
}
