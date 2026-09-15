using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The machine-to-machine channel-account registry - create accounts for
/// external systems (the seeded one is WEBSITE_GUEST), toggle them active/
/// inactive and regenerate the API key shown to that system once. The API
/// side gates every endpoint here with [Authorize(Policy = MANAGE_CHANNELS)]
/// (SuperAdmin-only via RolePermissions) - this [Authorize(Roles=SuperAdmin)]
/// is the matching "don't even show the screen" layer.
/// </summary>
[Authorize(Roles = RoleCodes.SuperAdmin)]
public class ChannelAccountsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public ChannelAccountsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var result = await _apiClient.GetAsync<List<ChannelAccountItem>>("/api/channel-accounts");

        var vm = new ChannelAccountsViewModel
        {
            Items = result.Success ? result.Data ?? new List<ChannelAccountItem>() : new List<ChannelAccountItem>(),
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        if (!result.Success)
        {
            vm.StatusMessage = result.Message;
            vm.StatusIsError = true;
        }

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateChannelAccountFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Channel name is required.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var result = await _apiClient.PostAsync<ChannelAccountCreated>("/api/channel-accounts", new
        {
            model.Channel,
            model.AllowedIpRange
        });

        TempData["StatusMessage"] = result.Success
            ? (result.Data != null
                ? $"Account \"{model.Channel}\" created - API key: {result.Data.ApiKey}"
                : $"Account \"{model.Channel}\" created.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleStatus(long id, bool isActive)
    {
        var result = await _apiClient.PutAsync<object>($"/api/channel-accounts/{id}/status", new { IsActive = isActive });

        TempData["StatusMessage"] = result.Success
            ? (isActive ? "Channel account activated." : "Channel account deactivated.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RegenerateKey(long id)
    {
        var result = await _apiClient.PostAsync<ChannelAccountKey>($"/api/channel-accounts/{id}/regenerate-key", new { });

        TempData["StatusMessage"] = result.Success
            ? (result.Data != null ? $"New API key: {result.Data.ApiKey}" : "API key regenerated.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    /// <summary>Mirrors ChannelAccountCreateResult (ServiceAccountId + ApiKey).</summary>
    public class ChannelAccountCreated
    {
        public long ServiceAccountId { get; set; }
        public string ApiKey { get; set; } = string.Empty;
    }

    /// <summary>Regenerate-key payload: { "apiKey": "..." }.</summary>
    public class ChannelAccountKey
    {
        public string ApiKey { get; set; } = string.Empty;
    }
}