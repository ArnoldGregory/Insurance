using InsurancePlatform.Api.Contracts.Clients;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Clients;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Client CRUD - staff-facing, plus one anonymous lookup endpoint used pre-registration.</summary>
// Create/Update/Delete require CreateClient/EditClient (seeded to AA/AG/SP
// - see RolePermissions in Insurance_API_Schema.sql; SA holds neither,
// matching its documented "cannot create clients/agents" role, and Agent
// specifically lost EditClient later - see that seed block's comment).
// GetById/GetList only require [Authorize], but are scoped by role in
// code: an Agent's list defaults to only clients they personally
// registered, and a Client-role caller can only fetch their OWN record via
// GetById - never anyone else's, even by guessing an id.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ClientsController : BaseApiController
{
    private readonly IClientRepository _clientRepository;
    private readonly IClientLookupService _clientLookupService;
    private readonly ILoggerManager _logger;

    public ClientsController(
        IClientRepository clientRepository,
        IClientLookupService clientLookupService,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _clientRepository = clientRepository;
        _clientLookupService = clientLookupService;
        _logger = logger;
    }

    /// <summary>Checks whether an ID number already has a client record, and if not, tries to prefill name/KRA PIN from GovConnect.</summary>
    /// <response code="200">Always 200 - check MatchStatus in the data, not Success (NOT_FOUND is a valid outcome, not a failure).</response>
    // Anonymous on purpose: has to be callable before someone has an
    // account, from the self-registration form - and also useful for
    // agent-assisted client creation (POST /clients), same endpoint either way.
    [AllowAnonymous]
    [HttpGet("resolve/{idNo}")]
    [ProducesResponseType(typeof(ApiResponse<ClientLookupResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Resolve(string idNo)
    {
        var result = await _clientLookupService.ResolveOrEnrichAsync(idNo);

        _logger.LogInfo($"Resolve id_no={idNo}: matchStatus={result.MatchStatus}, enrichedFromGovConnect={result.EnrichedFromGovConnect}.");

        return Success(result, "Resolved.");
    }

    /// <summary>Creates a client record with no login of its own - the staff equivalent of self-registration.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.CreateClient)]
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreateClientRequest request)
    {
        // registered_by_user_id is always the caller (CurrentUserId), taken
        // from their own JWT - never accepted from the request body.
        var result = await _clientRepository.CreateAsync(
            request.IdNo, request.FullName, request.Dob, request.Email, request.Phone,
            request.Address, request.KraPin, CurrentUserId, request.RegistrationChannel,
            "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Client create failed for id_no={request.IdNo}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Client created: client_id={result.Data}, id_no={request.IdNo}, by user_id={CurrentUserId}.");
        return Success(new { ClientId = result.Data }, result.ResultMessage);
    }

    /// <summary>Fetches one client - a Client-role caller can only fetch their own record.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<Client>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(long id)
    {
        var result = await _clientRepository.GetByIdAsync(id);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        // Same "not found" for both a missing id AND someone else's record
        // - never confirms "that id exists, you're just not allowed to see
        // it". Same reasoning as AuthService's deliberately vague login
        // failure message.
        if (CurrentRoleCode == RoleCodes.Client && result.Data.UserId != CurrentUserId)
        {
            return BusinessFailure("Client not found.");
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Lists/searches clients - staff-only, an Agent sees only clients they personally registered.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<ClientListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] string? search, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        // Agent scoping comes from the caller's own JWT, never a request
        // parameter - an Agent can't widen their view by passing someone
        // else's user_id. AgentAdmin/SupportAgent/SuperAdmin see everyone (null).
        long? registeredByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _clientRepository.GetListAsync(registeredByUserId, search, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Client_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dashboard stat-card counts (total + registered this month) - an Agent sees only clients they personally registered.</summary>
    // Same Agent-self-scoping as GetList above.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.Agent},{RoleCodes.SupportAgent}")]
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<ClientDashboardSummary>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary()
    {
        long? registeredByUserId = CurrentRoleCode == RoleCodes.Agent ? CurrentUserId : null;

        var result = await _clientRepository.GetSummaryAsync(registeredByUserId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Client_GetSummary returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Partial update (only the fields you send are changed) - EditClient holders only, currently AgentAdmin/SupportAgent.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.EditClient)]
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateClientRequest request)
    {
        var result = await _clientRepository.UpdateAsync(
            id, request.FullName, request.Dob, request.Email, request.Phone,
            request.Address, request.KraPin, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Client updated: client_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Soft delete (isdeleted = 1) - the row stays, just hidden from every Get/List query.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.EditClient)]
    [HttpDelete("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Delete(long id)
    {
        var result = await _clientRepository.DeleteAsync(id, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Client deleted (soft): client_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }
}
