namespace InsurancePlatform.Domain.Entities;

/// <summary>Flat admin view of one menu item - usp_Menu_GetList's row shape. Includes inactive rows, unlike the role-scoped tree a portal actually renders (see MenuTreeItem).</summary>
public class Menu
{
    public long MenuId { get; set; }
    public long? ParentMenuId { get; set; }
    public string Label { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public string? Url { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedOn { get; set; }
}

/// <summary>
/// One node in the role-scoped menu tree a portal renders directly after
/// login - assembled server-side (MenuRepository.GetForRoleAsync) from
/// usp_RoleMenu_GetForRole's flat, already-ordered rows, so the portal
/// never has to walk parent/child relationships itself. ParentMenuId is
/// carried along mainly for debugging/logging - a caller walking the tree
/// via Children never needs it.
/// </summary>
public class MenuTreeItem
{
    public long MenuId { get; set; }
    public long? ParentMenuId { get; set; }
    public string Label { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public string? Url { get; set; }
    public int SortOrder { get; set; }
    public List<MenuTreeItem> Children { get; set; } = new();
}
