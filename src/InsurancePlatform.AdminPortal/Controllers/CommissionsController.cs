using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Commission administration, split across the two menu entries the seed
/// tree defines: Manage (AA/SP) and Mine (AG).
///
/// Manage pulls the dashboard summary, every agent with their current rate
/// (the API has no "list all rates" endpoint - only per-agent, so it's one
/// /rate/by-agent call per agent; fine for a handful of agents) and the
/// pending-withdrawal queue for processing.
///
/// Mine is a pure read of /api/agent-commissions/me (+me/balance +
/// me/withdrawals) plus the manual withdrawal request button.
///
/// The class-level gate is AllStaff and each action narrows it further
/// ([Authorize] attributes AND across class+action) - matching each API
/// endpoint's own role list.
/// </summary>
[Authorize(Roles = RoleCodes.AllStaff)]
public class CommissionsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public CommissionsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    [Authorize(Roles = RoleCodes.CommissionsBackoffice)]
    public async Task<IActionResult> Manage()
    {
        var summaryResult = await _apiClient.GetAsync<AgentCommissionDashboardSummary>("/api/agent-commissions/summary");
        var agentsResult = await _apiClient.GetAsync<List<StaffOption>>("/api/staff?roleCode=AG&status=ACTIVE");
        var pendingResult = await _apiClient.GetAsync<List<CommissionWithdrawalQueueItem>>("/api/agent-commissions/withdrawals/pending");

        var agents = agentsResult.Success ? agentsResult.Data ?? new List<StaffOption>() : new List<StaffOption>();
        var ratesByAgent = new Dictionary<long, List<AgentCommissionRateItem>>();

        foreach (var agent in agents)
        {
            var rateResult = await _apiClient.GetAsync<List<AgentCommissionRateItem>>($"/api/agent-commissions/rate/by-agent/{agent.UserId}");
            ratesByAgent[agent.UserId] = rateResult.Success ? rateResult.Data ?? new List<AgentCommissionRateItem>() : new List<AgentCommissionRateItem>();
        }

        var vm = new ManageCommissionsViewModel
        {
            Summary = summaryResult.Success ? summaryResult.Data ?? new AgentCommissionDashboardSummary() : new AgentCommissionDashboardSummary(),
            Agents = agents,
            RatesByAgent = ratesByAgent,
            PendingWithdrawals = pendingResult.Success ? pendingResult.Data ?? new List<CommissionWithdrawalQueueItem>() : new List<CommissionWithdrawalQueueItem>(),
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        return View(vm);
    }

    [HttpGet]
    [Authorize(Roles = RoleCodes.Agent)]
    public async Task<IActionResult> Mine()
    {
        var balanceResult = await _apiClient.GetAsync<decimal>("/api/agent-commissions/me/balance");
        var ledgerResult = await _apiClient.GetAsync<AgentCommissionListPage>("/api/agent-commissions/me?pageSize=50");
        var withdrawalsResult = await _apiClient.GetAsync<List<CommissionWithdrawalItem>>("/api/agent-commissions/me/withdrawals");

        var balance = balanceResult.Success ? balanceResult.Data : 0m;

        var vm = new MyCommissionsViewModel
        {
            Balance = balance,
            Ledger = ledgerResult.Success ? ledgerResult.Data ?? new AgentCommissionListPage() : new AgentCommissionListPage(),
            Withdrawals = withdrawalsResult.Success ? withdrawalsResult.Data ?? new List<CommissionWithdrawalItem>() : new List<CommissionWithdrawalItem>(),
            CanRequestWithdrawal = balanceResult.Success && balance > 0,
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = RoleCodes.CommissionsBackoffice)]
    public async Task<IActionResult> SetRate(SetCommissionRateFormModel model)
    {
        var result = await _apiClient.PostAsync<object>("/api/agent-commissions/rate", new
        {
            model.AgentUserId,
            model.RatePercent,
            model.EffectiveFrom
        });

        TempData["StatusMessage"] = result.Success ? "Commission rate saved." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Manage));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = RoleCodes.CommissionsBackoffice)]
    public async Task<IActionResult> UpdateWithdrawalStatus(WithdrawalStatusFormModel model)
    {
        var result = await _apiClient.PutAsync<object>($"/api/agent-commissions/withdrawals/{model.WithdrawalId}/status", new
        {
            model.Status
        });

        TempData["StatusMessage"] = result.Success ? $"Withdrawal #{model.WithdrawalId} marked {model.Status}." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Manage));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = RoleCodes.Agent)]
    public async Task<IActionResult> RequestWithdrawal()
    {
        var result = await _apiClient.PostAsync<CommissionWithdrawalState>("/api/agent-commissions/withdrawals", new { });

        TempData["StatusMessage"] = result.Success
            ? (result.Data != null ? $"Withdrawal of {result.Data.Amount:N2} requested." : "Withdrawal requested.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Mine));
    }
}

public class CommissionWithdrawalState
{
    public long WithdrawalId { get; set; }
    public decimal Amount { get; set; }
}