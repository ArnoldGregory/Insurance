using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Menu - GET /api/menus's flat row shape (includes inactive rows, unlike GetAsync&lt;List&lt;MenuTreeItem&gt;&gt;("/api/menus/mine") which only ever returns what the CALLER can see).</summary>
public class MenuAdminItem
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
/// Everything Views/Menus/Index.cshtml needs: the full flat tree (already
/// parent-then-children ordered by usp_Menu_GetList), the 4 portal roles as
/// fixed grid columns, and which of those roles currently has each menu_id
/// granted - built by MenusController.Index by flattening GET /api/menus/
/// for-role/{roleCode}'s tree for each role and checking membership, since
/// the API has no single "grants for every role at once" endpoint.
/// </summary>
public class MenuIndexViewModel
{
    public List<MenuAdminItem> Items { get; set; } = new();
    public static readonly string[] Roles = { RoleCodes.SuperAdmin, RoleCodes.AgentAdmin, RoleCodes.Agent, RoleCodes.SupportAgent };
    public Dictionary<long, HashSet<string>> AccessByMenuId { get; set; } = new();
    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    public bool HasAccess(long menuId, string roleCode) =>
        AccessByMenuId.TryGetValue(menuId, out var roles) && roles.Contains(roleCode);
}

/// <summary>Shared by both the "add menu item" and "edit menu item" forms - MenuId is null for Create.</summary>
public class MenuFormViewModel
{
    public long? MenuId { get; set; }

    public long? ParentMenuId { get; set; }

    [Required(ErrorMessage = "Label is required.")]
    [StringLength(100)]
    public string Label { get; set; } = string.Empty;

    [Display(Name = "Icon (Font Awesome class, e.g. fa-users)")]
    [StringLength(50)]
    public string? Icon { get; set; }

    [Display(Name = "URL (leave blank for a group header)")]
    [StringLength(255)]
    public string? Url { get; set; }

    [Display(Name = "Sort order")]
    public int SortOrder { get; set; }

    /// <summary>Top-level items only - a menu can be at most 2 levels deep (see MenuViewComponent/usp_RoleMenu_GetForRole's doc comments), so a child cannot itself be picked as someone else's parent.</summary>
    public List<MenuAdminItem> ParentOptions { get; set; } = new();

    public string? ErrorMessage { get; set; }
}
