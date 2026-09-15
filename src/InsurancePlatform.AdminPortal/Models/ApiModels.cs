namespace InsurancePlatform.AdminPortal.Models;

/// <summary>
/// Mirrors InsurancePlatform.Api.Contracts.Common.ApiResponse&lt;T&gt; -
/// every response InsurancePlatform.Api returns, deserialized here since
/// this project deliberately doesn't reference that project's assembly
/// (see the .csproj's top-level comment). Keep this in sync by hand if the
/// API's envelope shape ever changes.
/// </summary>
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public string? Ref { get; set; }
}

/// <summary>Mirrors VerifyOtpData - the payload POST /api/auth/verify-otp returns on success.</summary>
public class VerifyOtpData
{
    public string Token { get; set; } = string.Empty;
    public string RoleCode { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
}

/// <summary>
/// One node in the role-scoped menu tree GET /api/menus/mine returns -
/// mirrors InsurancePlatform.Domain.Entities.MenuTreeItem. A node with an
/// empty Children list and a non-null Url is a direct link; a node with
/// children is a group header the layout renders as an expandable section.
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
