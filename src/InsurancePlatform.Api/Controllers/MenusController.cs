using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Menus;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>
/// Admin Portal navigation - menu CRUD and per-role visibility grants.
/// Deliberately separate from Permissions/RolePermissions: this controls
/// what a role SEES in the sidebar, not what the API actually ALLOWS - see
/// Menus/RoleMenus' comments in Insurance_API_Schema.sql. Every write here
/// (and the two admin-only reads) is gated by MANAGE_MENUS, currently
/// SuperAdmin-only, same reasoning as MANAGE_CHANNELS. GetMine is the one
/// exception - any authenticated portal role can ask for its own menu tree,
/// since that's exactly what the portal calls once right after login.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MenusController : BaseApiController
{
    private readonly IMenuRepository _menuRepository;
    private readonly ILoggerManager _logger;

    public MenusController(IMenuRepository menuRepository, ILoggerManager logger, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _menuRepository = menuRepository;
        _logger = logger;
    }

    /// <summary>Registers a new menu item (top-level, or a child of an existing one).</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreateMenuRequest request)
    {
        var result = await _menuRepository.CreateAsync(request.ParentMenuId, request.Label, request.Icon, request.Url, request.SortOrder, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Menu create failed for label={request.Label}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Menu created: menu_id={result.Data}, label={request.Label}, by user_id={CurrentUserId}.");
        return Success(new { MenuId = result.Data }, result.ResultMessage);
    }

    /// <summary>Partial update of a menu item's label/icon/url/sort_order.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateMenuRequest request)
    {
        var result = await _menuRepository.UpdateAsync(id, request.Label, request.Icon, request.Url, request.SortOrder, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Menu updated: menu_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Activates or deactivates a menu item. Deactivating a parent does not delete its children's own rows - see usp_Menu_SetActiveStatus's doc comment for how that interacts with what usp_RoleMenu_GetForRole returns.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpPut("{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetActiveStatus(long id, [FromBody] SetMenuActiveStatusRequest request)
    {
        var result = await _menuRepository.SetActiveStatusAsync(id, request.IsActive, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Menu status changed: menu_id={id}, is_active={request.IsActive}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Grants or revokes one role's access to one menu item.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpPut("{id}/role-access")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetRoleAccess(long id, [FromBody] SetMenuRoleAccessRequest request)
    {
        var result = await _menuRepository.SetRoleAccessAsync(request.RoleCode, id, request.CanAccess, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Menu role-access set failed for menu_id={id}, role_code={request.RoleCode}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Menu role-access set: menu_id={id}, role_code={request.RoleCode}, can_access={request.CanAccess}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Admin's flat list of every menu item, including inactive ones - for building the menu editor UI.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<Menu>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList()
    {
        var result = await _menuRepository.GetListAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Menu_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>The caller's own menu tree, built from their own JWT role claim - what the Admin Portal calls once right after login to render its sidebar. Any authenticated portal role may call this for itself.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("mine")]
    [ProducesResponseType(typeof(ApiResponse<List<MenuTreeItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMine()
    {
        var result = await _menuRepository.GetForRoleAsync(CurrentRoleCode);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_RoleMenu_GetForRole returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Admin lookup of another role's menu tree - e.g. a "what does Agent's sidebar look like" review screen.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManageMenus)]
    [HttpGet("for-role/{roleCode}")]
    [ProducesResponseType(typeof(ApiResponse<List<MenuTreeItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetForRole(string roleCode)
    {
        var result = await _menuRepository.GetForRoleAsync(roleCode);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }
}
