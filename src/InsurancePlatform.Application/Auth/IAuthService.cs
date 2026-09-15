namespace InsurancePlatform.Application.Auth;


public interface IAuthService
{
    Task<AuthResult> LoginAsync(string idNo, string password);

    /// <summary>
    /// channel (PORTAL or MOBILE) gets embedded in the issued token's
    /// "channel" claim - see ITokenService.GenerateToken.
    /// </summary>
    Task<TokenResult> VerifyOtpAsync(string idNo, string otpCode, string channel);

    /// <summary>
    /// Always returns a generic "if an account exists, a code was sent"
    /// style success message regardless of whether idNo actually matches
    /// anyone - same account-enumeration reasoning as LoginAsync's
    /// deliberately vague failure message, just applied to the success
    /// path instead, since a reset request itself shouldn't confirm
    /// whether an id_no is registered.
    /// </summary>
    Task<AuthResult> ForgotPasswordAsync(string idNo);

    /// <summary>Verifies the RESET_PASSWORD OTP and, on success, sets the new password via usp_User_UpdatePassword.</summary>
    Task<AuthResult> ResetPasswordAsync(string idNo, string otpCode, string newPassword);

    /// <summary>
    /// USSD/WhatsApp channel-service login - single step, no OTP (a
    /// machine credential, not a human needing 2FA). channel must be one
    /// ChannelServiceAccounts actually has a row for (USSD/WHATSAPP);
    /// apiKey is the raw plaintext key, hashed here and compared to the
    /// account's stored hash.
    /// </summary>
    Task<TokenResult> ChannelLoginAsync(string channel, string apiKey);
}


public class AuthResult
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
}

public class TokenResult : AuthResult
{
    public string? Token { get; init; }
    public string? RoleCode { get; init; }
    public DateTime? ExpiresAtUtc { get; init; }
}
