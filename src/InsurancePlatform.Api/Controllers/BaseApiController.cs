using System.Security.Claims;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;


public abstract class BaseApiController : ControllerBase
{
    private readonly CorrelationContext _correlationContext;

    protected BaseApiController(CorrelationContext correlationContext)
    {
        _correlationContext = correlationContext;
    }

    protected string CorrelationRef => _correlationContext.Ref;

    /// <summary>
    /// The caller's own user_id, read off the JWT's NameIdentifier claim
    /// (see JwtTokenService.GenerateToken). Only meaningful behind
    /// [Authorize] - on an anonymous action this throws, since there's no
    /// token to read it from. Centralized here (rather than each controller
    /// parsing User.FindFirstValue itself) because ClientsController and
    /// VehiclesController both need it for audit actor_id and for
    /// Client-role ownership checks.
    /// </summary>
    protected long CurrentUserId => long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new InvalidOperationException("No NameIdentifier claim on the current user - this action must be [Authorize]-protected."));

    /// <summary>The caller's role_code (SA/AA/AG/SP/CL/CS), off the JWT's Role claim.</summary>
    protected string CurrentRoleCode => User.FindFirstValue(ClaimTypes.Role) ?? string.Empty;

    protected IActionResult Success<T>(T data, string message = "Success") => Ok(ApiResponse<T>.Ok(data, message, CorrelationRef));

    protected IActionResult Success(string message = "Success") => Ok(ApiResponse<object?>.Ok(null, message, CorrelationRef));

    protected IActionResult BusinessFailure(string message) => Ok(ApiResponse<object?>.Fail(message, CorrelationRef));

    protected IActionResult ServerError(string message) => StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object?>.Fail(message, CorrelationRef));
}
