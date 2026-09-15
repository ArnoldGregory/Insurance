using System.Security.Cryptography;
using System.Text;

namespace InsurancePlatform.Application.Auth;

/// <summary>
/// Shared hashing/generation logic for ChannelServiceAccounts.api_key_hash -
/// extracted out of AuthService (which only ever verified an existing key)
/// so ChannelAccountsController can reuse the exact same hash algorithm
/// when a SuperAdmin registers a new channel or rotates one's key. Plain
/// SHA-256, not BCrypt - same reasoning AuthService documented: a
/// channel-service API key is a long, system-generated, high-entropy
/// secret exchanged out-of-band (not a human-memorized password), so
/// BCrypt's deliberate slowness isn't buying any real protection here,
/// it would just cost CPU on every single channel-login call.
/// </summary>
public static class ApiKeyHasher
{
    public static string Hash(string apiKey)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(apiKey));
        return Convert.ToHexString(bytes);
    }

    /// <summary>
    /// Generates a brand-new plaintext key - 32 cryptographically random
    /// bytes, base64url-encoded (no padding) so it's safe to paste
    /// straight into a curl command, .env file, or JSON body without
    /// escaping. This is the ONLY moment the plaintext exists - the
    /// caller must hash it (via Hash() above) before it's ever persisted,
    /// and must return it to the SuperAdmin in the API response since
    /// there is no way to recover it after that.
    /// </summary>
    public static string GenerateKey()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }
}
