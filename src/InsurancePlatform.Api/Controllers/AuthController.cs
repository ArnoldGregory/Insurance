using System.Security.Claims;
using InsurancePlatform.Api.Contracts.Auth;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

// No class-level [AllowAnonymous] anymore - it used to sit here, but that
// would have silently defeated [Authorize] on Me() below. ASP.NET Core's
// rule is "AllowAnonymous anywhere in scope wins", not "most specific
// attribute wins" - a controller-level [AllowAnonymous] short-circuits
// authorization for every action inside it, even ones explicitly marked
// [Authorize]. So each of the four originally-public actions now carries
// its own [AllowAnonymous] instead, and Me() is the only one that needs a
// valid JWT.
[ApiController]
[Route("api/[controller]")]
public class AuthController : BaseApiController
{
    private readonly IAuthService _authService;
    private readonly IRegistrationService _registrationService;

    public AuthController(IAuthService authService, IRegistrationService registrationService, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _authService = authService;
        _registrationService = registrationService;
    }

    /// <summary>Step 1 of login - checks the password and sends an OTP.</summary>
    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await _authService.LoginAsync(request.IdNo, request.Password);
        return result.Success ? Success(result.Message) : BusinessFailure(result.Message);
    }

    /// <summary>Step 2 of login - verifies the OTP and returns a JWT.</summary>
    [AllowAnonymous]
    [HttpPost("verify-otp")]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpData>), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
    {
        var result = await _authService.VerifyOtpAsync(request.IdNo, request.OtpCode, request.Channel);

        if (!result.Success)
        {
            return BusinessFailure(result.Message);
        }

        var data = new VerifyOtpData
        {
            Token = result.Token!,
            RoleCode = result.RoleCode!,
            ExpiresAtUtc = result.ExpiresAtUtc!.Value
        };

        return Success(data, result.Message);
    }

    /// <summary>Step 1 of self-registration (portal or mobile only) - creates the account and sends an OTP.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [AllowAnonymous]
    [HttpPost("register")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var input = new ClientRegistrationInput
        {
            IdNo = request.IdNo,
            FullName = request.FullName,
            Dob = request.Dob,
            Email = request.Email,
            Phone = request.Phone,
            Address = request.Address,
            KraPin = request.KraPin,
            Password = request.Password,
            RegistrationChannel = request.RegistrationChannel
        };

        var result = await _registrationService.RegisterAsync(input);
        return result.Success ? Success(result.Message) : BusinessFailure(result.Message);
    }

    /// <summary>Step 2 of self-registration - verifies the OTP, activates the account, and returns a JWT.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [AllowAnonymous]
    [HttpPost("verify-registration-otp")]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpData>), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyRegistrationOtp([FromBody] VerifyOtpRequest request)
    {
        // Registration completes straight into a logged-in state here - no
        // separate /login call needed afterward.
        var result = await _registrationService.VerifyRegistrationOtpAsync(request.IdNo, request.OtpCode, request.Channel);

        if (!result.Success)
        {
            return BusinessFailure(result.Message);
        }

        var data = new VerifyOtpData
        {
            Token = result.Token!,
            RoleCode = result.RoleCode!,
            ExpiresAtUtc = result.ExpiresAtUtc!.Value
        };

        return Success(data, result.Message);
    }

    /// <summary>Returns the caller's own identity and permissions, read from their JWT.</summary>
    /// <response code="200">Always 200 when the token is valid - check Success in the body.</response>
    /// <response code="401">Missing, malformed, expired, or invalid-signature token.</response>
    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<MeData>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult Me()
    {
        // No database read here at all - everything below was written into
        // the token by JwtTokenService at login/registration time; this
        // just reads it back off HttpContext.User, which ASP.NET Core
        // populated during UseAuthentication() after validating the
        // token's signature.
        var data = new MeData
        {
            UserId = long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),
            RoleCode = User.FindFirstValue(ClaimTypes.Role) ?? string.Empty,
            FullName = User.FindFirstValue("full_name") ?? string.Empty,
            Permissions = User.FindAll("permission").Select(c => c.Value).ToList()
        };

        return Success(data, "Current user.");
    }

    /// <summary>Step 1 of password reset - sends an OTP if the ID number has an account.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [AllowAnonymous]
    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        // Always returns the same success message whether or not idNo
        // actually matches an account - see AuthService.ForgotPasswordAsync's
        // doc comment for the account-enumeration reasoning.
        var result = await _authService.ForgotPasswordAsync(request.IdNo);
        return Success(result.Message);
    }

    /// <summary>Step 2 of password reset - verifies the OTP and sets a new password.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [AllowAnonymous]
    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        var result = await _authService.ResetPasswordAsync(request.IdNo, request.OtpCode, request.NewPassword);
        return result.Success ? Success(result.Message) : BusinessFailure(result.Message);
    }

    /// <summary>USSD/WhatsApp channel-service login - a machine credential, one call straight to a token.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [AllowAnonymous]
    [HttpPost("channel-login")]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpData>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ChannelLogin([FromBody] ChannelLoginRequest request)
    {
        var result = await _authService.ChannelLoginAsync(request.Channel, request.ApiKey);

        if (!result.Success)
        {
            return BusinessFailure(result.Message);
        }

        var data = new VerifyOtpData
        {
            Token = result.Token!,
            RoleCode = result.RoleCode!,
            ExpiresAtUtc = result.ExpiresAtUtc!.Value
        };

        return Success(data, result.Message);
    }
}
