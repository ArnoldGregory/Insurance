using System.Security.Cryptography;
using System.Text;
using InsurancePlatform.Application.Notifications;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Auth;


public class AuthService : IAuthService
{
    private const string TargetTypeUser = "USER";
    private const string LoginPurpose = "LOGIN";
    private const string ResetPasswordPurpose = "RESET_PASSWORD";
    private const int OtpExpiryMinutes = 5;

    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IOtpRepository _otpRepository;
    private readonly IChannelServiceRepository _channelServiceRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IOtpNotificationSender _otpSender;
    private readonly ITokenService _tokenService;
    private readonly ILoggerManager _logger;
    private readonly IConfiguration _configuration;

    public AuthService(
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        IOtpRepository otpRepository,
        IChannelServiceRepository channelServiceRepository,
        IPasswordHasher passwordHasher,
        IOtpNotificationSender otpSender,
        ITokenService tokenService,
        ILoggerManager logger,
        IConfiguration configuration)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _otpRepository = otpRepository;
        _channelServiceRepository = channelServiceRepository;
        _passwordHasher = passwordHasher;
        _otpSender = otpSender;
        _tokenService = tokenService;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<AuthResult> LoginAsync(string idNo, string password)
    {
        var userResult = await _userRepository.GetByIdNoForLoginAsync(idNo);

       
        const string invalidCredentialsMessage = "Invalid ID number or password.";

        if (!userResult.IsSuccess || userResult.Data is null)
        {
            _logger.LogWarn($"Login failed - id_no not found: {idNo}");
            return new AuthResult { Success = false, Message = invalidCredentialsMessage };
        }

        var user = userResult.Data;

        // LOCKED gets its own distinct message (not the generic "not
        // active" one) - usp_User_GetByIdNoForLogin already auto-unlocked
        // this account above if its cooldown had passed, so seeing LOCKED
        // here means the caller is still within the 15-minute window from
        // usp_User_RecordFailedLogin's most recent lockout.
        if (string.Equals(user.Status, "LOCKED", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarn($"Login blocked - account is locked for id_no: {idNo}");
            return new AuthResult { Success = false, Message = "This account is temporarily locked due to repeated failed login attempts. Please try again later." };
        }

        if (!string.Equals(user.Status, "ACTIVE", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarn($"Login blocked - account status is {user.Status} for id_no: {idNo}");
            return new AuthResult { Success = false, Message = "This account is not active. Contact support." };
        }

        if (!_passwordHasher.Verify(password, user.PasswordHash))
        {
            _logger.LogWarn($"Login failed - incorrect password for id_no: {idNo}");

            // Fire-and-check, not fire-and-forget: still return the same
            // vague invalidCredentialsMessage regardless of whether this
            // attempt just triggered a lockout - an attacker probing
            // passwords sees identical responses on attempt 1 and attempt
            // 5. The lockout only becomes visible on their NEXT attempt,
            // via the LOCKED branch above.
            var failResult = await _userRepository.RecordFailedLoginAsync(user.UserId);
            if (!failResult.IsSuccess)
            {
                _logger.LogError($"usp_User_RecordFailedLogin failed for user_id={user.UserId}: {failResult.ResultMessage}");
            }

            return new AuthResult { Success = false, Message = invalidCredentialsMessage };
        }

        var recordResult = await _userRepository.RecordSuccessfulLoginAsync(user.UserId);
        if (!recordResult.IsSuccess)
        {
            _logger.LogError($"usp_User_RecordSuccessfulLogin failed for user_id={user.UserId}: {recordResult.ResultMessage}");
        }

        var otpCode = GenerateOtpCode();
        var otpHash = HashOtp(otpCode);

       
        var sendingByEmail = !string.IsNullOrWhiteSpace(user.Email);
        var destination = sendingByEmail ? user.Email! : user.Phone;

        var createResult = await _otpRepository.CreateAsync(TargetTypeUser, user.UserId, destination, LoginPurpose, otpHash, OtpExpiryMinutes);
        if (!createResult.IsSuccess)
        {
            _logger.LogError($"Login OTP could not be created for id_no={idNo}: {createResult.ResultMessage}");
            return new AuthResult { Success = false, Message = "Could not start login - please try again." };
        }

        var externalRefNumber = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
        var sent = sendingByEmail
            ? await _otpSender.SendOtpEmailAsync(user.Email!, user.FullName, otpCode, externalRefNumber)
            : await _otpSender.SendOtpSmsAsync(user.Phone, otpCode, externalRefNumber);

        if (!sent)
        {
            _logger.LogError($"Login OTP created (otp_id={createResult.Data}) but gateway delivery failed for id_no={idNo}.");
            if (!bool.TryParse(_configuration["Notifications:AllowOtpDeliveryFailure"], out var allowWithoutDelivery) || !allowWithoutDelivery)
            {
                return new AuthResult { Success = false, Message = "Could not deliver your verification code - please try again." };
            }
        }

        _logger.LogInfo($"Login OTP sent for id_no={idNo} via {(sendingByEmail ? "email" : "sms")}.");
        return new AuthResult { Success = true, Message = "Verification code sent." };
    }

    public async Task<TokenResult> VerifyOtpAsync(string idNo, string otpCode, string channel)
    {
        if (!IsValidChannel(channel))
        {
            return new TokenResult { Success = false, Message = "channel must be PORTAL or MOBILE." };
        }

        var userResult = await _userRepository.GetByIdNoForLoginAsync(idNo);
        if (!userResult.IsSuccess || userResult.Data is null)
        {
            return new TokenResult { Success = false, Message = "Invalid ID number or code." };
        }

        var user = userResult.Data;
        var otpHash = HashOtp(otpCode);

        var verifyResult = await _otpRepository.VerifyAsync(TargetTypeUser, user.UserId, LoginPurpose, otpHash);
        if (!verifyResult.IsSuccess)
        {
            _logger.LogWarn($"OTP verify failed for id_no={idNo}: {verifyResult.ResultMessage}");
            return new TokenResult { Success = false, Message = verifyResult.ResultMessage };
        }

        var permissionsResult = await _roleRepository.GetPermissionCodesAsync(user.RoleId);
        var permissions = permissionsResult.IsSuccess && permissionsResult.Data is not null ? permissionsResult.Data : new List<string>();

        var issuedToken = _tokenService.GenerateToken(user, permissions, channel);

        _logger.LogInfo($"Login successful for id_no={idNo}, role={user.RoleCode}, channel={channel}.");

        return new TokenResult
        {
            Success = true,
            Message = "Login successful.",
            Token = issuedToken.Token,
            RoleCode = user.RoleCode,
            ExpiresAtUtc = issuedToken.ExpiresAtUtc
        };
    }

    public async Task<AuthResult> ForgotPasswordAsync(string idNo)
    {
        const string genericMessage = "If an account exists for this ID number, a verification code has been sent.";

        var userResult = await _userRepository.GetByIdNoForLoginAsync(idNo);
        if (!userResult.IsSuccess || userResult.Data is null)
        {
            // Deliberately still "successful" from the caller's point of
            // view - same account-enumeration reasoning as everywhere else
            // in this file. A nonexistent id_no looks identical to a real
            // one that just got a code sent.
            _logger.LogWarn($"Forgot-password requested for unknown id_no: {idNo}");
            return new AuthResult { Success = true, Message = genericMessage };
        }

        var user = userResult.Data;
        var otpCode = GenerateOtpCode();
        var otpHash = HashOtp(otpCode);

        var sendingByEmail = !string.IsNullOrWhiteSpace(user.Email);
        var destination = sendingByEmail ? user.Email! : user.Phone;

        var createResult = await _otpRepository.CreateAsync(TargetTypeUser, user.UserId, destination, ResetPasswordPurpose, otpHash, OtpExpiryMinutes);
        if (!createResult.IsSuccess)
        {
            _logger.LogError($"Reset-password OTP could not be created for id_no={idNo}: {createResult.ResultMessage}");
            return new AuthResult { Success = true, Message = genericMessage };
        }

        var externalRefNumber = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
        var sent = sendingByEmail
            ? await _otpSender.SendOtpEmailAsync(user.Email!, user.FullName, otpCode, externalRefNumber)
            : await _otpSender.SendOtpSmsAsync(user.Phone, otpCode, externalRefNumber);

        if (!sent)
        {
            _logger.LogError($"Reset-password OTP created (otp_id={createResult.Data}) but gateway delivery failed for id_no={idNo}.");
        }
        else
        {
            _logger.LogInfo($"Reset-password OTP sent for id_no={idNo} via {(sendingByEmail ? "email" : "sms")}.");
        }

        return new AuthResult { Success = true, Message = genericMessage };
    }

    public async Task<AuthResult> ResetPasswordAsync(string idNo, string otpCode, string newPassword)
    {
        var userResult = await _userRepository.GetByIdNoForLoginAsync(idNo);
        if (!userResult.IsSuccess || userResult.Data is null)
        {
            return new AuthResult { Success = false, Message = "Invalid ID number or code." };
        }

        var user = userResult.Data;
        var otpHash = HashOtp(otpCode);

        var verifyResult = await _otpRepository.VerifyAsync(TargetTypeUser, user.UserId, ResetPasswordPurpose, otpHash);
        if (!verifyResult.IsSuccess)
        {
            _logger.LogWarn($"Reset-password OTP verify failed for id_no={idNo}: {verifyResult.ResultMessage}");
            return new AuthResult { Success = false, Message = verifyResult.ResultMessage };
        }

        var newHash = _passwordHasher.Hash(newPassword);
        var updateResult = await _userRepository.UpdatePasswordAsync(user.UserId, newHash, TargetTypeUser, user.UserId);
        if (!updateResult.IsSuccess)
        {
            _logger.LogError($"usp_User_UpdatePassword failed for id_no={idNo}: {updateResult.ResultMessage}");
            return new AuthResult { Success = false, Message = updateResult.ResultMessage };
        }

        _logger.LogInfo($"Password reset completed for id_no={idNo}.");
        return new AuthResult { Success = true, Message = "Password has been reset. You can now log in with your new password." };
    }

    public async Task<TokenResult> ChannelLoginAsync(string channel, string apiKey)
    {
        var accountResult = await _channelServiceRepository.GetByChannelAsync(channel);
        if (!accountResult.IsSuccess || accountResult.Data is null)
        {
            // Same channel value used for both "no such channel" and
            // "wrong key" - no reason to help a caller distinguish which
            // one they got wrong.
            _logger.LogWarn($"Channel login failed - no active account for channel: {channel}");
            return new TokenResult { Success = false, Message = "Invalid channel or API key." };
        }

        var account = accountResult.Data;
        var providedKeyHash = HashApiKey(apiKey);

        if (!string.Equals(providedKeyHash, account.ApiKeyHash, StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarn($"Channel login failed - API key mismatch for channel: {channel}");
            return new TokenResult { Success = false, Message = "Invalid channel or API key." };
        }

        var permissionsResult = await _roleRepository.GetPermissionCodesAsync(account.RoleId);
        var permissions = permissionsResult.IsSuccess && permissionsResult.Data is not null ? permissionsResult.Data : new List<string>();

        var issuedToken = _tokenService.GenerateChannelServiceToken(account.ServiceAccountId, account.RoleCode, permissions, channel);

        _logger.LogInfo($"Channel login successful for channel={channel}, service_account_id={account.ServiceAccountId}.");

        return new TokenResult
        {
            Success = true,
            Message = "Channel login successful.",
            Token = issuedToken.Token,
            RoleCode = account.RoleCode,
            ExpiresAtUtc = issuedToken.ExpiresAtUtc
        };
    }

    /// <summary>
    /// PORTAL/MOBILE are the only channels an individual (Client or staff)
    /// login/registration can declare - USSD/WHATSAPP/WEBSITE_GUEST only
    /// ever authenticate via ChannelLoginAsync, never through this check.
    /// </summary>
    internal static bool IsValidChannel(string? channel) => channel is "PORTAL" or "MOBILE";

   
    private static string GenerateOtpCode() => "111111";

    // Deliberately plain SHA-256, not BCrypt, for the OTP hash. BCrypt's
    // slowness is valuable for *password* hashes because it makes offline
    // brute-forcing expensive - but an OTP is a 6-digit code (only a million
    // possibilities) that expires in 5 minutes and is already locked after 5
    // wrong attempts by usp_Otp_Verify itself, so a slow hash buys nothing
    // extra here and would just waste CPU on every single verification call.
    private static string HashOtp(string otpCode)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(otpCode));
        return Convert.ToHexString(bytes);
    }

    // Same plain-SHA-256 reasoning as HashOtp: a channel-service API key is
    // a long, system-generated, high-entropy secret exchanged out-of-band
    // (not a human-memorized password), so BCrypt's deliberate slowness
    // isn't buying any real protection here either - it would just cost
    // CPU on every single channel-login call. Convert.ToHexString uses
    // uppercase hex; the seed data's api_key_hash values were generated
    // lowercase (Python's hashlib), so the comparison in ChannelLoginAsync
    // is case-insensitive rather than relying on matching casing.
    private static string HashApiKey(string apiKey) => ApiKeyHasher.Hash(apiKey);
}
