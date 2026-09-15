using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The screen that lets a SuperAdmin do exactly what the very first request
/// for this whole Admin Portal asked for: "register my menus at the
/// database then retrieve them from there" - register new sidebar items,
/// edit/deactivate existing ones, and control which of the 4 portal roles
/// (SA/AA/AG/SP) can see each one, all without touching SQL directly.
/// Gated to SuperAdmin only, matching MANAGE_MENUS on the API side (every
/// write here calls an endpoint [Authorize(Policy = PermissionCodes.
/// ManageMenus)]-protected there too - this [Authorize(Roles=...)] is a
/// UX-level "don't even show the menu/screen", not the real enforcement).
/// </summary>
[Authorize(Roles = RoleCodes.SuperAdmin)]
public class MenusController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public MenusController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var vm = await BuildIndexViewModelAsync();
        return View(vm);
    }

    [HttpGet]
    public async Task<IActionResult> Create(long? parentMenuId)
    {
        var items = await GetFlatListAsync();
        var form = new MenuFormViewModel
        {
            ParentMenuId = parentMenuId,
            SortOrder = 0,
            ParentOptions = items.Where(i => i.ParentMenuId == null).OrderBy(i => i.SortOrder).ToList()
        };
        return View(form);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(MenuFormViewModel model)
    {
        if (!ModelState.IsValid)
        {
            model.ParentOptions = (await GetFlatListAsync()).Where(i => i.ParentMenuId == null).OrderBy(i => i.SortOrder).ToList();
            return View(model);
        }

        var result = await _apiClient.PostAsync<object>("/api/menus", new
        {
            ParentMenuId = model.ParentMenuId,
            Label = model.Label,
            Icon = model.Icon,
            Url = model.Url,
            SortOrder = model.SortOrder
        });

        if (!result.Success)
        {
            model.ErrorMessage = result.Message;
            model.ParentOptions = (await GetFlatListAsync()).Where(i => i.ParentMenuId == null).OrderBy(i => i.SortOrder).ToList();
            return View(model);
        }

        TempData["StatusMessage"] = $"\"{model.Label}\" was added.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(long id)
    {
        var items = await GetFlatListAsync();
        var item = items.FirstOrDefault(i => i.MenuId == id);

        if (item is null)
        {
            TempData["StatusMessage"] = "That menu item no longer exists.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var form = new MenuFormViewModel
        {
            MenuId = item.MenuId,
            ParentMenuId = item.ParentMenuId,
            Label = item.Label,
            Icon = item.Icon,
            Url = item.Url,
            SortOrder = item.SortOrder,
            ParentOptions = items.Where(i => i.ParentMenuId == null && i.MenuId != id).OrderBy(i => i.SortOrder).ToList()
        };
        return View(form);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(MenuFormViewModel model)
    {
        if (model.MenuId is null)
        {
            return RedirectToAction(nameof(Index));
        }

        if (!ModelState.IsValid)
        {
            model.ParentOptions = (await GetFlatListAsync()).Where(i => i.ParentMenuId == null && i.MenuId != model.MenuId).OrderBy(i => i.SortOrder).ToList();
            return View(model);
        }

        // Edit only ever changes label/icon/url/sort_order - a menu item's
        // parent is fixed at creation (see usp_Menu_Update's doc comment:
        // there's no proc to re-parent an existing item).
        var result = await _apiClient.PutAsync<object>($"/api/menus/{model.MenuId}", new
        {
            Label = model.Label,
            Icon = model.Icon,
            Url = model.Url,
            SortOrder = model.SortOrder
        });

        if (!result.Success)
        {
            model.ErrorMessage = result.Message;
            model.ParentOptions = (await GetFlatListAsync()).Where(i => i.ParentMenuId == null && i.MenuId != model.MenuId).OrderBy(i => i.SortOrder).ToList();
            return View(model);
        }

        TempData["StatusMessage"] = $"\"{model.Label}\" was updated.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleStatus(long id, bool isActive)
    {
        var result = await _apiClient.PutAsync<object>($"/api/menus/{id}/status", new { IsActive = isActive });

        TempData["StatusMessage"] = result.Success
            ? (isActive ? "Menu item reactivated." : "Menu item deactivated.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetRoleAccess(long menuId, string roleCode, bool canAccess)
    {
        var result = await _apiClient.PutAsync<object>($"/api/menus/{menuId}/role-access", new { RoleCode = roleCode, CanAccess = canAccess });

        if (!result.Success)
        {
            TempData["StatusMessage"] = result.Message;
            TempData["StatusIsError"] = true;
        }

        return RedirectToAction(nameof(Index));
    }

    private async Task<List<MenuAdminItem>> GetFlatListAsync()
    {
        var result = await _apiClient.GetAsync<List<MenuAdminItem>>("/api/menus");
        return result.Success ? result.Data ?? new List<MenuAdminItem>() : new List<MenuAdminItem>();
    }

    /// <summary>
    /// GET /api/menus (usp_Menu_GetList) has no per-role "who can see this"
    /// column - that only exists implicitly, one role at a time, via GET
    /// /api/menus/for-role/{roleCode} (usp_RoleMenu_GetForRole). So to build
    /// a single [menu x role] checkbox grid, this calls that endpoint once
    /// per role (4 calls - MenuIndexViewModel.Roles) and flattens each
    /// role's returned tree (parents + their Children) into a HashSet of
    /// menu_ids that role can currently see.
    /// </summary>
    private async Task<MenuIndexViewModel> BuildIndexViewModelAsync()
    {
        var items = await GetFlatListAsync();
        var accessByMenuId = new Dictionary<long, HashSet<string>>();

        foreach (var roleCode in MenuIndexViewModel.Roles)
        {
            var result = await _apiClient.GetAsync<List<MenuTreeItem>>($"/api/menus/for-role/{roleCode}");
            var tree = result.Success ? result.Data ?? new List<MenuTreeItem>() : new List<MenuTreeItem>();

            foreach (var menuId in FlattenIds(tree))
            {
                if (!accessByMenuId.TryGetValue(menuId, out var roles))
                {
                    roles = new HashSet<string>();
                    accessByMenuId[menuId] = roles;
                }
                roles.Add(roleCode);
            }
        }

        var statusMessage = TempData["StatusMessage"] as string;
        var statusIsError = TempData["StatusIsError"] is true;

        return new MenuIndexViewModel
        {
            Items = items,
            AccessByMenuId = accessByMenuId,
            StatusMessage = statusMessage,
            StatusIsError = statusIsError
        };
    }

    private static IEnumerable<long> FlattenIds(List<MenuTreeItem> tree)
    {
        foreach (var item in tree)
        {
            yield return item.MenuId;
            foreach (var childId in FlattenIds(item.Children))
            {
                yield return childId;
            }
        }
    }
}
