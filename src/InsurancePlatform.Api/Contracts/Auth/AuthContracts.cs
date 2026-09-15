namespace InsurancePlatform.Api.Contracts.Auth;

public class LoginRequest
{
    public string IdNo { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}
public class VerifyOtpRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;

    /// <summary>PORTAL or MOBILE - gets locked into the token's "channel" claim.</summary>
    // This is the ONE call that actually mints a token (both for login and
    // for registration - this same class is reused for /verify-otp and
    // /verify-registration-otp). Every later request must send the same
    // value back as an X-Channel header, or ChannelBindingMiddleware
    // rejects it - a token minted here with "PORTAL" will not work from a
    // request declaring X-Channel: MOBILE, even for the exact same account.
    public string Channel { get; set; } = string.Empty;
}

public class VerifyOtpData
{
    public string Token { get; set; } = string.Empty;
    public string RoleCode { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
}

/// <summary>Self-registration from the mobile app or portal.</summary>
// Only IdNo, FullName, Phone, Password and RegistrationChannel are
// non-nullable - matches Clients' own NOT NULL columns exactly, so
// Swagger's required-field red-asterisk marking lines up with what the
// database actually requires.
public class RegisterRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime? Dob { get; set; }
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? KraPin { get; set; }
    public string Password { get; set; } = string.Empty;

    /// <summary>PORTAL or MOBILE only.</summary>
    // Self-registration is not available from USSD, WhatsApp or the public
    // website (those channels never carry an individual login).
    // usp_Client_SelfRegister enforces this same rule.
    public string RegistrationChannel { get; set; } = string.Empty;
}

/// <summary>GET /api/auth/me's response body.</summary>
// Everything here is read straight off the caller's own JWT claims, no
// database round-trip.
public class MeData
{
    public long UserId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public List<string> Permissions { get; set; } = new();
}

public class ForgotPasswordRequest
{
    public string IdNo { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>USSD/WhatsApp channel-service login.</summary>
// A machine credential for a whole gateway, not an individual person, so
// this is just {Channel, ApiKey}, no OTP round-trip like the human-facing
// login flows.
public class ChannelLoginRequest
{
    /// <summary>USSD or WHATSAPP - must match a row in ChannelServiceAccounts.</summary>
    public string Channel { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
}
