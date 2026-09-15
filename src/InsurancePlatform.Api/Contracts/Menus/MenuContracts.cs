namespace InsurancePlatform.Api.Contracts.Menus;

public class CreateMenuRequest
{
    /// <summary>NULL for a top-level item.</summary>
    public long? ParentMenuId { get; set; }
    public string Label { get; set; } = string.Empty;
    public string? Icon { get; set; }

    /// <summary>NULL for a group header with children - see Menus.url's schema comment.</summary>
    public string? Url { get; set; }
    public int? SortOrder { get; set; }
}

/// <summary>Partial update - a null field keeps its current value (see usp_Menu_Update's doc comment for the one consequence of that: there's no way to explicitly clear Icon/Url back to null through this request alone).</summary>
public class UpdateMenuRequest
{
    public string? Label { get; set; }
    public string? Icon { get; set; }
    public string? Url { get; set; }
    public int? SortOrder { get; set; }
}

public class SetMenuActiveStatusRequest
{
    public bool IsActive { get; set; }
}

/// <summary>Grants or revokes one role's access to one menu item. RoleCode is SA/AA/AG/SP/CL/CS (see RoleCodes) - MenuId comes from the route.</summary>
public class SetMenuRoleAccessRequest
{
    public string RoleCode { get; set; } = string.Empty;
    public bool CanAccess { get; set; }
}
