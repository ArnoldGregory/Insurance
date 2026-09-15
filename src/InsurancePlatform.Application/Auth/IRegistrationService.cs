namespace InsurancePlatform.Application.Auth;

/// <summary>
/// Self-registration: a brand-new person (mobile app or portal) creating
/// their own account, as opposed to AuthService's LoginAsync/VerifyOtpAsync
/// (an existing account logging in). Two steps, same shape as login:
/// register (creates the account INACTIVE, sends an OTP) then verify
/// (activates the account and issues a JWT - registration completes
/// straight into a logged-in state, no separate login call needed after).
/// </summary>
public interface IRegistrationService
{
    Task<AuthResult> RegisterAsync(ClientRegistrationInput input);

    /// <summary>
    /// channel (PORTAL or MOBILE) gets embedded in the issued token's
    /// "channel" claim - see ITokenService.GenerateToken. Passed here
    /// rather than at RegisterAsync time because the token is only ever
    /// minted at this final verify step.
    /// </summary>
    Task<TokenResult> VerifyRegistrationOtpAsync(string idNo, string otpCode, string channel);
}

/// <summary>
/// Everything self-registration needs. Dob/Email/Address/KraPin are
/// nullable - matches the Clients table columns exactly (only id_no,
/// full_name and phone are NOT NULL there).
/// </summary>
public class ClientRegistrationInput
{
    public string IdNo { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public DateTime? Dob { get; init; }
    public string? Email { get; init; }
    public string Phone { get; init; } = string.Empty;
    public string? Address { get; init; }
    public string? KraPin { get; init; }
    public string Password { get; init; } = string.Empty;

    /// <summary>
    /// PORTAL or MOBILE only. Narrower than Clients.registration_channel's
    /// table-level CHECK constraint (which still allows USSD/WHATSAPP/
    /// WEBSITE for other creation paths, e.g. an agent using
    /// usp_Client_Create) - self-registration specifically is restricted to
    /// the two channels that carry an individual login.
    /// </summary>
    public string RegistrationChannel { get; init; } = string.Empty;
}
