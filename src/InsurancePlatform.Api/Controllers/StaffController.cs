using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Staff;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Creates staff/portal-login accounts - Super_Admin -> Agent_admin, Agent_admin -> Agent/Support_Agent.</summary>
// Two endpoints instead of one generic "create staff with any role code"
// action, on purpose: each endpoint's [Authorize(Policy=...)] attribute
// alone enforces who's allowed to call it (CreateAdmin for SA, CreateAgent
// for AA), matching CommissionRatesController/PricingController's existing
// pattern of gating writes behind a permission policy rather than a role
// list. CreateAgent additionally validates roleCode in code, since
// CREATE_AGENT covers both AG and SP per the RolePermissions seed - an
// AgentAdmin still can't use it to mint another AgentAdmin or SuperAdmin.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class StaffController : BaseApiController
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ILoggerManager _logger;

    public StaffController(IUserRepository userRepository, IPasswordHasher passwordHasher, ILoggerManager logger, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _logger = logger;
    }

    /// <summary>Super_Admin creates an Agent_admin account - starts ACTIVE, must change password on first login.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.CreateAdmin)]
    [HttpPost("agent-admins")]
    [ProducesResponseType(typeof(ApiResponse<CreateStaffData>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateAgentAdmin([FromBody] CreateAgentAdminRequest request)
    {
        var passwordHash = _passwordHasher.Hash(request.Password);

        var result = await _userRepository.CreateAsync(
            RoleCodes.AgentAdmin, request.IdNo, request.FullName, request.Email, request.Phone, passwordHash, CurrentUserId);

        if (!result.IsSuccess || result.Data is null)
        {
            _logger.LogWarn($"Agent_admin creation failed for id_no={request.IdNo}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Agent_admin created: user_id={result.Data}, id_no={request.IdNo}, by user_id={CurrentUserId}.");
        return Success(new CreateStaffData { UserId = result.Data.Value }, result.ResultMessage);
    }

    /// <summary>Super_Admin OR Agent_admin creates a Support_Agent account - starts ACTIVE, must change password on first login.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    // Gated by ROLES (SA+AA) rather than a permission policy, because the
    // RolePermissions seed only grants CREATE_AGENT to AgentAdmin - yet this
    // screen is meant to be usable by both Super_Admin and Agent_admin. The
    // endpoint always creates SP, so there's no roleCode to forge.
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin}")]
    [HttpPost("support-agents")]
    [ProducesResponseType(typeof(ApiResponse<CreateStaffData>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateSupportAgent([FromBody] CreateSupportAgentRequest request)
    {
        var passwordHash = _passwordHasher.Hash(request.Password);

        var result = await _userRepository.CreateAsync(
            RoleCodes.SupportAgent, request.IdNo, request.FullName, request.Email, request.Phone, passwordHash, CurrentUserId);

        if (!result.IsSuccess || result.Data is null)
        {
            _logger.LogWarn($"Support_Agent creation failed for id_no={request.IdNo}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Support_Agent created: user_id={result.Data}, id_no={request.IdNo}, by user_id={CurrentUserId}.");
        return Success(new CreateStaffData { UserId = result.Data.Value }, result.ResultMessage);
    }

    /// <summary>
    /// Super_Admin or Agent_admin silently soft-deletes a Support_Agent
    /// account (usp_User_Delete: isdeleted=1 + status INACTIVE, so the
    /// account vanishes from every list and can no longer log in, but the
    /// row is kept for audit). Deliberately limited to Support_Agent
    /// targets - this is the support-management screen's delete, and an SA
    /// or AA account can't be removed by it. A caller can't delete themself.
    /// </summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin}")]
    [HttpDelete("{userId:long}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteSupportAgent(long userId)
    {
        if (userId == CurrentUserId)
        {
            return BusinessFailure("You cannot delete your own account.");
        }

        var target = await _userRepository.GetByIdAsync(userId);

        if (!target.IsSuccess || target.Data is null)
        {
            _logger.LogWarn($"Support_Agent delete aborted for user_id={userId}: {target.ResultMessage}");
            return BusinessFailure(target.ResultMessage);
        }

        if (target.Data.RoleCode != RoleCodes.SupportAgent)
        {
            _logger.LogWarn($"Support_Agent delete rejected for user_id={userId}: target role is {target.Data.RoleCode}, not SP.");
            return BusinessFailure("Only Support_Agent accounts can be deleted.");
        }

        var result = await _userRepository.DeleteAsync(userId, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Support_Agent delete failed for user_id={userId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Support_Agent soft-deleted: user_id={userId}, full_name={target.Data.FullName}, by user_id={CurrentUserId}.");
        return Success("Support Agent deleted.");
    }

    /// <summary>
    /// Lists staff, optionally filtered by role - built for the Quote
    /// Requests "assign to a specific Support person" dropdown
    /// (roleCode=SP), but general enough to reuse for any other staff
    /// picker later. Restricted to the same backoffice roles that can see
    /// the quote work-queue itself - there's no reason a plain Agent needs
    /// a directory of every Support account.
    /// </summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<StaffOption>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] string? roleCode, [FromQuery] string? status = "ACTIVE", [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 100)
    {
        var result = await _userRepository.GetListAsync(roleCode, null, status, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_User_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard stat-card counts: total agents, and agents who sold at least one policy in the last 30 days. Same backoffice-only access as GetList.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("agent-counts")]
    [ProducesResponseType(typeof(ApiResponse<AgentCounts>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAgentCounts()
    {
        var result = await _userRepository.GetAgentCountsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_User_GetAgentCounts returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }
}
