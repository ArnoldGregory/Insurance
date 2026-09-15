using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Underwriters;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Underwriter CRUD - the insurance companies whose products this platform sells.</summary>
// Create/Update/SetActiveStatus require MANAGE_UNDERWRITER, seeded to
// AgentAdmin only (see RolePermissions in Insurance_API_Schema.sql).
// GetById/GetList are restricted to back-office staff (SuperAdmin/
// AgentAdmin/SupportAgent) - Agent does NOT get direct underwriter
// browsing access. Agent's path to "which underwriters can I buy this
// from" is PricingController.GetTpoPriceOptions, which already returns
// underwriterId/underwriterName inline alongside the price - there's no
// legitimate reason for Agent to browse the raw underwriter list/detail
// outside that comparison-shopping flow.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UnderwritersController : BaseApiController
{
    private readonly IUnderwriterRepository _underwriterRepository;
    private readonly IUnderwriterPolicyLevelNumberRepository _policyLevelNumberRepository;
    private readonly ILoggerManager _logger;

    public UnderwritersController(
        IUnderwriterRepository underwriterRepository,
        IUnderwriterPolicyLevelNumberRepository policyLevelNumberRepository,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _underwriterRepository = underwriterRepository;
        _policyLevelNumberRepository = policyLevelNumberRepository;
        _logger = logger;
    }

    /// <summary>Registers a new underwriter.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageUnderwriter)]
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreateUnderwriterRequest request)
    {
        var result = await _underwriterRepository.CreateAsync(request.Name, request.Code, request.ContactEmail, request.ContactPhone, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Underwriter create failed for code={request.Code}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Underwriter created: underwriter_id={result.Data}, code={request.Code}, by user_id={CurrentUserId}.");
        return Success(new { UnderwriterId = result.Data }, result.ResultMessage);
    }

    /// <summary>Fetches one underwriter by id.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<Underwriter>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(long id)
    {
        var result = await _underwriterRepository.GetByIdAsync(id);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Lists underwriters, optionally filtered to active-only.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<UnderwriterSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool? activeOnly)
    {
        var result = await _underwriterRepository.GetListAsync(activeOnly);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Underwriter_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Full update of an underwriter's contact details.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageUnderwriter)]
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateUnderwriterRequest request)
    {
        var result = await _underwriterRepository.UpdateAsync(id, request.Name, request.ContactEmail, request.ContactPhone, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Underwriter updated: underwriter_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Activates or deactivates an underwriter.</summary>
    // Deactivating doesn't delete anything - it's a soft gate that
    // usp_Purchase_Create checks (an inactive underwriter can't be used on
    // a new purchase), while existing purchases/prices referencing it are
    // untouched.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageUnderwriter)]
    [HttpPut("{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetActiveStatus(long id, [FromBody] SetUnderwriterActiveStatusRequest request)
    {
        var result = await _underwriterRepository.SetActiveStatusAsync(id, request.IsActive, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Underwriter status changed: underwriter_id={id}, is_active={request.IsActive}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Sets whether this underwriter reuses one fixed policy_number per policy_level (FIXED) or gets a fresh auto-generated one per purchase (CHANGE).</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageUnderwriter)]
    [HttpPut("{id}/policy-type")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetPolicyType(long id, [FromBody] SetUnderwriterPolicyTypeRequest request)
    {
        var result = await _underwriterRepository.SetPolicyTypeAsync(id, request.PolicyType, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Underwriter policy_type changed: underwriter_id={id}, policy_type={request.PolicyType}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Registers or corrects the one fixed, reused policy_number this underwriter stamps on every certificate at a given policy_level. Only meaningful for FIXED underwriters, but callable regardless (so the number can be on file before the switch is flipped).</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageUnderwriter)]
    [HttpPut("{id}/policy-level-numbers")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetPolicyLevelNumber(long id, [FromBody] SetUnderwriterPolicyLevelNumberRequest request)
    {
        var result = await _policyLevelNumberRepository.SetAsync(id, request.PolicyLevelId, request.PolicyNumber, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Underwriter policy-level-number set failed for underwriter_id={id}, policy_level_id={request.PolicyLevelId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Underwriter policy-level-number set: underwriter_id={id}, policy_level_id={request.PolicyLevelId}, id={result.Data}, by user_id={CurrentUserId}.");
        return Success(new { Id = result.Data }, result.ResultMessage);
    }

    /// <summary>Lists registered fixed policy numbers, optionally filtered to one underwriter.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}")]
    [HttpGet("policy-level-numbers")]
    [ProducesResponseType(typeof(ApiResponse<List<UnderwriterPolicyLevelNumber>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPolicyLevelNumbers([FromQuery] long? underwriterId)
    {
        var result = await _policyLevelNumberRepository.GetListAsync(underwriterId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_UnderwriterPolicyLevelNumber_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }
}
