using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IMenuRepository
{
    /// <summary>Wraps usp_Menu_Create.</summary>
    Task<StoredProcResult<long?>> CreateAsync(long? parentMenuId, string label, string? icon, string? url, int? sortOrder, long actorId);

    /// <summary>Wraps usp_Menu_Update - partial update, NULL fields leave the current value unchanged.</summary>
    Task<StoredProcResult> UpdateAsync(long menuId, string? label, string? icon, string? url, int? sortOrder, long actorId);

    /// <summary>Wraps usp_Menu_SetActiveStatus.</summary>
    Task<StoredProcResult> SetActiveStatusAsync(long menuId, bool isActive, long actorId);

    /// <summary>Wraps usp_Menu_GetList - the flat admin view, includes inactive rows.</summary>
    Task<StoredProcResult<List<Menu>>> GetListAsync();

    /// <summary>Wraps usp_RoleMenu_SetAccess - grants (canAccess = true) or revokes a role's access to one menu item.</summary>
    Task<StoredProcResult> SetRoleAccessAsync(string roleCode, long menuId, bool canAccess, long actorId);

    /// <summary>Wraps usp_RoleMenu_GetForRole, then assembles the flat rows into a nested tree - what the Admin Portal renders after login.</summary>
    Task<StoredProcResult<List<MenuTreeItem>>> GetForRoleAsync(string roleCode);
}
