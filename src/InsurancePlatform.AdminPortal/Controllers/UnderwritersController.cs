using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The Underwriters catalog - list/edit/deactivate underwriters plus the
/// policy-level number allocations each one holds. Gated to QuoteBackoffice
/// (SA/AA/SP) for reads, matching GET /api/underwriters's role list on the
/// API side; the write endpoints are [Authorize(Policy = MANAGE_UNDERWRITER)]
/// there too and that's the real enforcement (this [Authorize(Roles=...)] is
/// just the "don't even show the screen" layer, same pattern as Menus).
/// </summary>
[Authorize(Roles = RoleCodes.QuoteBackoffice)]
public class UnderwritersController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public UnderwritersController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index(bool showInactive = false)
    {
        var listResult = await _apiClient.GetAsync<List<UnderwriterItem>>($"/api/underwriters{(showInactive ? "" : "?activeOnly=true")}");
        var plnsResult = await _apiClient.GetAsync<List<UnderwriterPolicyLevelNumberItem>>("/api/underwriters/policy-level-numbers");
        var levelsResult = await _apiClient.GetAsync<List<PolicyLevelOption>>("/api/products/policy-levels");

        ViewBag.PolicyLevels = levelsResult.Success ? levelsResult.Data ?? new List<PolicyLevelOption>() : new List<PolicyLevelOption>();

        var vm = new UnderwritersIndexViewModel
        {
            Items = listResult.Success ? listResult.Data ?? new List<UnderwriterItem>() : new List<UnderwriterItem>(),
            PolicyLevelNumbers = plnsResult.Success ? plnsResult.Data ?? new List<UnderwriterPolicyLevelNumberItem>() : new List<UnderwriterPolicyLevelNumberItem>(),
            ShowInactive = showInactive,
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        if (!listResult.Success)
        {
            vm.StatusMessage = listResult.Message;
            vm.StatusIsError = true;
        }

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(UnderwriterFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Fill in the required fields.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var result = model.UnderwriterId.HasValue
            ? await _apiClient.PutAsync<object>($"/api/underwriters/{model.UnderwriterId}", new
            {
                model.Name,
                model.ContactEmail,
                model.ContactPhone
            })
            : await _apiClient.PostAsync<object>("/api/underwriters", new
            {
                model.Name,
                model.Code,
                model.ContactEmail,
                model.ContactPhone
            });

        TempData["StatusMessage"] = result.Success
            ? (model.UnderwriterId.HasValue ? "Underwriter updated." : $"Underwriter \"{model.Name}\" created.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleStatus(long id, bool isActive)
    {
        var result = await _apiClient.PutAsync<object>($"/api/underwriters/{id}/status", new { IsActive = isActive });

        TempData["StatusMessage"] = result.Success
            ? (isActive ? "Underwriter reactivated." : "Underwriter deactivated.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetPolicyType(long id, string policyType)
    {
        var result = await _apiClient.PutAsync<object>($"/api/underwriters/{id}/policy-type", new { PolicyType = policyType });

        TempData["StatusMessage"] = result.Success ? "Policy numbering type updated." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SavePolicyLevelNumber(PolicyLevelNumberFormModel model)
    {
        var result = await _apiClient.PutAsync<object>($"/api/underwriters/{model.UnderwriterId}/policy-level-numbers", new
        {
            PolicyLevelId = model.PolicyLevelId,
            PolicyNumber = model.PolicyNumber
        });

        TempData["StatusMessage"] = result.Success ? $"Number \"{model.PolicyNumber}\" allocated." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }
}