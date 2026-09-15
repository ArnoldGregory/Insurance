using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Staff management, split across two menu entries: Agent Admins (SA only)
/// and Agents (AA only). Both are a list of existing users (GET /api/staff
/// filtered by role) plus a create modal (POST /api/staff/agent-admins vs
/// POST /api/staff/agents). The two actions carry their own narrower
/// [Authorize(Roles=...)] and the class gate is AllStaff - matching the
/// seeded Staff menu group (SA,AA).
/// </summary>
[Authorize(Roles = RoleCodes.AllStaff)]
public class StaffController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public StaffController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    [Authorize(Roles = RoleCodes.SuperAdmin)]
    public async Task<IActionResult> AgentAdmins()
    {
        var result = await _apiClient.GetAsync<List<StaffUserItem>>("/api/staff?roleCode=AA&status=ACTIVE");

        var vm = new AgentAdminsViewModel
        {
            Items = result.Success ? result.Data ?? new List<StaffUserItem>() : new List<StaffUserItem>(),
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

    [HttpGet]
    [Authorize(Roles = RoleCodes.AgentAdmin)]
    public async Task<IActionResult> Agents()
    {
        var listResult = await _apiClient.GetAsync<List<StaffUserItem>>("/api/staff?roleCode=AG&status=ACTIVE");
        var countsResult = await _apiClient.GetAsync<AgentCounts>("/api/staff/agent-counts");

        var vm = new AgentsViewModel
        {
            Items = listResult.Success ? listResult.Data ?? new List<StaffUserItem>() : new List<StaffUserItem>(),
            TotalCount = countsResult.Success ? countsResult.Data?.TotalAgentCount ?? 0 : 0,
            ActiveCount = countsResult.Success ? countsResult.Data?.ActiveAgentCount ?? 0 : 0,
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

    [HttpGet]
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin}")]
    public async Task<IActionResult> SupportAgents()
    {
        var result = await _apiClient.GetAsync<List<StaffUserItem>>("/api/staff?roleCode=SP&status=ACTIVE");

        var vm = new SupportAgentsViewModel
        {
            Items = result.Success ? result.Data ?? new List<StaffUserItem>() : new List<StaffUserItem>(),
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
    [Authorize(Roles = RoleCodes.SuperAdmin)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAgentAdmin(CreateStaffFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Fill in all required fields.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(AgentAdmins));
        }

        var result = await _apiClient.PostAsync<object>("/api/staff/agent-admins", new
        {
            model.IdNo,
            model.FullName,
            model.Email,
            model.Phone,
            model.Password
        });

        TempData["StatusMessage"] = result.Success ? $"Agent Admin \"{model.FullName}\" created." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(AgentAdmins));
    }

    [HttpPost]
    [Authorize(Roles = RoleCodes.AgentAdmin)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAgent(CreateStaffFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Fill in all required fields.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Agents));
        }

        var result = await _apiClient.PostAsync<object>("/api/staff/agents", new
        {
            RoleCode = RoleCodes.Agent,
            model.IdNo,
            model.FullName,
            model.Email,
            model.Phone,
            model.Password
        });

        TempData["StatusMessage"] = result.Success ? $"Agent \"{model.FullName}\" created." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Agents));
    }

    [HttpPost]
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateSupportAgent(CreateStaffFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Fill in all required fields.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(SupportAgents));
        }

        var result = await _apiClient.PostAsync<object>("/api/staff/support-agents", new
        {
            model.IdNo,
            model.FullName,
            model.Email,
            model.Phone,
            model.Password
        });

        TempData["StatusMessage"] = result.Success ? $"Support Agent \"{model.FullName}\" created." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(SupportAgents));
    }

    [HttpPost]
    [Authorize(Roles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteSupportAgent(long id)
    {
        var result = await _apiClient.DeleteAsync<object>($"/api/staff/{id}");

        TempData["StatusMessage"] = result.Success ? "Support Agent deleted." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(SupportAgents));
    }
}