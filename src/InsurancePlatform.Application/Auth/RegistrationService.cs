using System.Security.Cryptography;
using System.Text;
using InsurancePlatform.Application.Notifications;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Auth;

/// <summary>
/// Mirrors AuthService's shape closely on purpose - same dependencies, same
/// OTP-hashing approach, same "vague failure message" reasoning where it
/// applies. The real difference is RegisterAsync creates a brand-new
/// account (via IClientRepository.SelfRegisterAsync) instead of checking an
/// existing one, and VerifyRegistrationOtpAsync activates the account
/// (IUserRepository.UpdateStatusAsync) before issuing a token, since a
/// freshly-registered account starts INACTIVE by design.
/// </summary>
public class RegistrationService : IRegistrationService
{
    private const string TargetTypeUser = "USER";
    private const string RegisterPurpose = "REGISTER";
    private const int OtpExpiryMinutes = 5;

    private readonly IClientRepository _clientRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IOtpRepository _otpRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IOtpNotificationSender _otpSender;
    private readonly ITokenService _tokenService;
    private readonly ILoggerManager _logger;
    private readonly IConfiguration _configuration;

    public RegistrationService(
        IClientRepository clientRepository,
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        IOtpRepository otpRepository,
        IPasswordHasher passwordHasher,
        IOtpNotificationSender otpSender,
        ITokenService tokenService,
        ILoggerManager logger,
        IConfiguration configuration)
    {
        _clientRepository = clientRepository;
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _otpRepository = otpRepository;
        _passwordHasher = passwordHasher;
        _otpSender = otpSender;
        _tokenService = tokenService;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<AuthResult> RegisterAsync(ClientRegistrationInput input)
    {
        var passwordHash = _passwordHasher.Hash(input.Password);

        var createResult = await _clientRepository.SelfRegisterAsync(
            input.IdNo, input.FullName, input.Dob, input.Email, input.Phone,
            input.Address, input.KraPin, passwordHash, input.RegistrationChannel);

        if (!createResult.IsSuccess || createResult.Data is null)
        {
            // usp_Client_SelfRegister's own messages already distinguish
            // "you have a login, log in instead" from "a client record
            // exists, use attach-login instead" - safe to pass straight
            // through, unlike login's deliberately-vague message, because
            // there's no account-enumeration risk here: the caller just
            // told us this id_no themselves, moments ago, in this same call.
            _logger.LogWarn($"Self-registration failed for id_no={input.IdNo}: {createResult.ResultMessage}");
            return new AuthResult { Success = false, Message = createResult.ResultMessage };
        }

        var ids = createResult.Data;
        var otpCode = GenerateOtpCode();
        var otpHash = HashOtp(otpCode);

        var sendingByEmail = !string.IsNullOrWhiteSpace(input.Email);
        var destination = sendingByEmail ? input.Email! : input.Phone;

        var otpCreateResult = await _otpRepository.CreateAsync(TargetTypeUser, ids.UserId, destination, RegisterPurpose, otpHash, OtpExpiryMinutes);
        if (!otpCreateResult.IsSuccess)
        {
            _logger.LogError($"Registration OTP could not be created for id_no={input.IdNo}: {otpCreateResult.ResultMessage}");
            return new AuthResult { Success = false, Message = "Account created but could not start verification - please try logging in to resend a code." };
        }

        var externalRefNumber = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
        var sent = sendingByEmail
            ? await _otpSender.SendOtpEmailAsync(input.Email!, input.FullName, otpCode, externalRefNumber)
            : await _otpSender.SendOtpSmsAsync(input.Phone, otpCode, externalRefNumber);

        if (!sent)
        {
            _logger.LogError($"Registration OTP created (otp_id={otpCreateResult.Data}) but gateway delivery failed for id_no={input.IdNo}.");
            if (!bool.TryParse(_configuration["Notifications:AllowOtpDeliveryFailure"], out var allowWithoutDelivery) || !allowWithoutDelivery)
            {
                return new AuthResult { Success = false, Message = "Account created but the verification code could not be delivered - please try again shortly." };
            }
        }

        _logger.LogInfo($"Registration OTP sent for id_no={input.IdNo} (user_id={ids.UserId}, client_id={ids.ClientId}) via {(sendingByEmail ? "email" : "sms")}.");
        return new AuthResult { Success = true, Message = "Account created. Verification code sent - verify to activate your account." };
    }

    public async Task<TokenResult> VerifyRegistrationOtpAsync(string idNo, string otpCode, string channel)
    {
        if (!AuthService.IsValidChannel(channel))
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

        var verifyResult = await _otpRepository.VerifyAsync(TargetTypeUser, user.UserId, RegisterPurpose, otpHash);
        if (!verifyResult.IsSuccess)
        {
            _logger.LogWarn($"Registration OTP verify failed for id_no={idNo}: {verifyResult.ResultMessage}");
            return new TokenResult { Success = false, Message = verifyResult.ResultMessage };
        }

        var activateResult = await _userRepository.UpdateStatusAsync(user.UserId, "ACTIVE", TargetTypeUser, user.UserId);
        if (!activateResult.IsSuccess)
        {
            _logger.LogError($"Registration OTP verified but account activation failed for id_no={idNo}: {activateResult.ResultMessage}");
            return new TokenResult { Success = false, Message = "Verification succeeded but activation failed - please try logging in shortly." };
        }

        var permissionsResult = await _roleRepository.GetPermissionCodesAsync(user.RoleId);
        var permissions = permissionsResult.IsSuccess && permissionsResult.Data is not null
            ? permissionsResult.Data
            : new List<string>();

        var issuedToken = _tokenService.GenerateToken(user, permissions, channel);

        _logger.LogInfo($"Registration complete and activated for id_no={idNo}, user_id={user.UserId}, channel={channel}.");

        return new TokenResult
        {
            Success = true,
            Message = "Account verified and activated.",
            Token = issuedToken.Token,
            RoleCode = user.RoleCode,
            ExpiresAtUtc = issuedToken.ExpiresAtUtc
        };
    }

    private static string GenerateOtpCode() => "111111";

    private static string HashOtp(string otpCode)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(otpCode));
        return Convert.ToHexString(bytes);
    }
}
