using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;

namespace InsurancePlatform.AdminPortal.ViewComponents;

/// <summary>
/// Renders the sidebar from the signed-in user's own menu tree
/// (GET /api/menus/mine) - invoked once from _Layout.cshtml on every page,
/// so every controller/view in this app automatically gets the right,
/// role-scoped navigation without having to fetch it itself. Cached
/// per-user for a few minutes (IMemoryCache, not distributed - see
/// Program.cs's comment on AddMemoryCache) so it isn't refetched from the
/// API on literally every page render; a role's menu grants changing mid-
/// session means the sidebar can lag behind by up to that cache window,
/// which is an acceptable trade-off here (same "re-login to pick up a
/// change" trade-off the JWT's own permission claims already have).
/// </summary>
public class MenuViewComponent : ViewComponent
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

    private readonly IInsuranceApiClient _apiClient;
    private readonly IMemoryCache _cache;

    public MenuViewComponent(IInsuranceApiClient apiClient, IMemoryCache cache)
    {
        _apiClient = apiClient;
        _cache = cache;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        var userId = HttpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(userId))
        {
            // Not signed in (e.g. rendering the login page's layout, if it
            // shares this layout) - nothing to show.
            return View(new List<MenuTreeItem>());
        }

        var cacheKey = $"menu-tree:{userId}";

        if (!_cache.TryGetValue(cacheKey, out List<MenuTreeItem>? tree))
        {
            var result = await _apiClient.GetAsync<List<MenuTreeItem>>("/api/menus/mine");
            tree = result.Success ? result.Data ?? new List<MenuTreeItem>() : new List<MenuTreeItem>();
            _cache.Set(cacheKey, tree, CacheDuration);
        }

        return View(tree);
    }
}
