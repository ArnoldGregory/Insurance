using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class MenuRepository : IMenuRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public MenuRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(long? parentMenuId, string label, string? icon, string? url, int? sortOrder, long actorId)
    {
        var menuIdParam = new MySqlParameter("o_menu_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_parent_menu_id", (object?)parentMenuId ?? DBNull.Value),
            new("p_label", label),
            new("p_icon", (object?)icon ?? DBNull.Value),
            new("p_url", (object?)url ?? DBNull.Value),
            new("p_sort_order", (object?)sortOrder ?? DBNull.Value),
            new("p_actor_id", actorId),
            menuIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Menu_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = menuIdParam.Value is null or DBNull ? null : Convert.ToInt64(menuIdParam.Value)
        };
    }

    public Task<StoredProcResult> UpdateAsync(long menuId, string? label, string? icon, string? url, int? sortOrder, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_menu_id", menuId),
            new("p_label", (object?)label ?? DBNull.Value),
            new("p_icon", (object?)icon ?? DBNull.Value),
            new("p_url", (object?)url ?? DBNull.Value),
            new("p_sort_order", (object?)sortOrder ?? DBNull.Value),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Menu_Update", parameters);
    }

    public Task<StoredProcResult> SetActiveStatusAsync(long menuId, bool isActive, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_menu_id", menuId),
            new("p_is_active", isActive),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Menu_SetActiveStatus", parameters);
    }

    public Task<StoredProcResult<List<Menu>>> GetListAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Menu_GetList", Array.Empty<MySqlParameter>(), MapMenuRow);
    }

    public Task<StoredProcResult> SetRoleAccessAsync(string roleCode, long menuId, bool canAccess, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_role_code", roleCode),
            new("p_menu_id", menuId),
            new("p_can_access", canAccess),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_RoleMenu_SetAccess", parameters);
    }

    public async Task<StoredProcResult<List<MenuTreeItem>>> GetForRoleAsync(string roleCode)
    {
        var parameters = new List<MySqlParameter> { new("p_role_code", roleCode) };
        var flatResult = await _executor.ExecuteQueryAsync("usp_RoleMenu_GetForRole", parameters, MapTreeItemRow);

        return new StoredProcResult<List<MenuTreeItem>>
        {
            ResultCode = flatResult.ResultCode,
            ResultMessage = flatResult.ResultMessage,
            Data = flatResult.Data is null ? null : BuildTree(flatResult.Data)
        };
    }

    // The proc already orders rows "each top-level item immediately
    // followed by its own children, in display order" - this just buckets
    // children under their ParentMenuId and returns only the top-level
    // (ParentMenuId == null) items, since a portal renders top-down from
    // there via each node's Children list.
    private static List<MenuTreeItem> BuildTree(List<MenuTreeItem> flatRows)
    {
        var byId = flatRows.ToDictionary(r => r.MenuId);
        var roots = new List<MenuTreeItem>();

        foreach (var row in flatRows)
        {
            if (row.ParentMenuId is long parentId && byId.TryGetValue(parentId, out var parent))
            {
                parent.Children.Add(row);
            }
            else
            {
                roots.Add(row);
            }
        }

        return roots;
    }

    private static Menu MapMenuRow(MySqlDataReader reader)
    {
        return new Menu
        {
            MenuId = reader.GetInt64("menu_id"),
            ParentMenuId = reader.IsDBNull(reader.GetOrdinal("parent_menu_id")) ? null : reader.GetInt64("parent_menu_id"),
            Label = reader.GetString("label"),
            Icon = reader.IsDBNull(reader.GetOrdinal("icon")) ? null : reader.GetString("icon"),
            Url = reader.IsDBNull(reader.GetOrdinal("url")) ? null : reader.GetString("url"),
            SortOrder = reader.GetInt32("sort_order"),
            IsActive = reader.GetBoolean("is_active"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static MenuTreeItem MapTreeItemRow(MySqlDataReader reader)
    {
        return new MenuTreeItem
        {
            MenuId = reader.GetInt64("menu_id"),
            ParentMenuId = reader.IsDBNull(reader.GetOrdinal("parent_menu_id")) ? null : reader.GetInt64("parent_menu_id"),
            Label = reader.GetString("label"),
            Icon = reader.IsDBNull(reader.GetOrdinal("icon")) ? null : reader.GetString("icon"),
            Url = reader.IsDBNull(reader.GetOrdinal("url")) ? null : reader.GetString("url"),
            SortOrder = reader.GetInt32("sort_order")
        };
    }
}
