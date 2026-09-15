using System.Diagnostics;
using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The portal's landing page after login - a role-aware dashboard. Which
/// stat cards show up depends on the signed-in user's role (see
/// DashboardViewModel's own doc comment for the exact split): back-office
/// roles (SuperAdmin/AgentAdmin/SupportAgent) get the platform-wide picture
/// (quote request queue, purchases, payments, clients, commissions moving
/// through the whole agent network); Agent gets their own personal numbers
/// only (their own purchases/payments/clients, their own commission
/// balance) - two back-office-only API endpoints (quote requests summary,
/// platform commission totals) are simply never called for that role, since
/// an Agent's JWT would get a 403 from either anyway.
/// </summary>
[Authorize]
public class HomeController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public HomeController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Index()
    {
        var roleCode = User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;
        var fullName = User.FindFirst("full_name")?.Value ?? "Staff";

        var vm = new DashboardViewModel
        {
            RoleCode = roleCode,
            FullName = fullName
        };

        if (roleCode == RoleCodes.Agent)
        {
            // Agent's own numbers - PurchasesController/PaymentsController/
            // ClientsController's GetSummary actions all auto-scope to
            // "just this caller" when the JWT's role is Agent (see those
            // API actions' own comments), so no query param is needed here
            // to ask for that - it's the same endpoint the back-office
            // branch below calls, just returning a narrower result because
            // of who's asking.
            var purchaseTask = _apiClient.GetAsync<PurchaseDashboardSummary>("/api/purchases/summary");
            var paymentTask = _apiClient.GetAsync<PaymentDashboardSummary>("/api/payments/summary");
            var clientTask = _apiClient.GetAsync<ClientDashboardSummary>("/api/clients/summary");
            var balanceTask = _apiClient.GetAsync<decimal>("/api/agentcommissions/me/balance");

            await Task.WhenAll(purchaseTask, paymentTask, clientTask, balanceTask);

            vm.PurchaseSummary = purchaseTask.Result.Success ? purchaseTask.Result.Data : null;
            vm.PaymentSummary = paymentTask.Result.Success ? paymentTask.Result.Data : null;
            vm.ClientSummary = clientTask.Result.Success ? clientTask.Result.Data : null;
            vm.MyCommissionBalance = balanceTask.Result.Success ? balanceTask.Result.Data : null;
        }
        else
        {
            // SuperAdmin/AgentAdmin/SupportAgent - the full back-office
            // picture, platform-wide. All eleven calls are independent of
            // each other, so they run in parallel the same way
            // QuoteRequestsController.Index fetches its list+summary+staff.
            // The last six (period totals, agent counts, top underwriters,
            // product sales, monthly trend, top agents) back the charts/
            // tables added for the BIMA_D_LINE-style dashboard layout -
            // every one of their API endpoints is itself SA/AA/SP-only, so
            // none of this runs for an Agent caller (see the branch above).
            var quoteTask = _apiClient.GetAsync<List<QuoteRequestProductSummary>>("/api/quoterequests/summary");
            var purchaseTask = _apiClient.GetAsync<PurchaseDashboardSummary>("/api/purchases/summary");
            var paymentTask = _apiClient.GetAsync<PaymentDashboardSummary>("/api/payments/summary");
            var clientTask = _apiClient.GetAsync<ClientDashboardSummary>("/api/clients/summary");
            var commissionTask = _apiClient.GetAsync<AgentCommissionDashboardSummary>("/api/agentcommissions/summary");
            var periodTask = _apiClient.GetAsync<PurchasePeriodTotals>("/api/purchases/period-totals");
            var agentCountsTask = _apiClient.GetAsync<AgentCounts>("/api/staff/agent-counts");
            var underwriterTask = _apiClient.GetAsync<List<UnderwriterSalesSummary>>("/api/purchases/by-underwriter");
            var productTask = _apiClient.GetAsync<List<ProductSalesSummary>>("/api/purchases/by-product");
            var trendTask = _apiClient.GetAsync<List<MonthlyTrendPoint>>("/api/purchases/monthly-trend");
            var topAgentsTask = _apiClient.GetAsync<List<TopAgentSummary>>("/api/purchases/top-agents");

            await Task.WhenAll(
                quoteTask, purchaseTask, paymentTask, clientTask, commissionTask,
                periodTask, agentCountsTask, underwriterTask, productTask, trendTask, topAgentsTask);

            vm.QuoteRequestSummary = quoteTask.Result.Success ? quoteTask.Result.Data ?? new() : new();
            vm.PurchaseSummary = purchaseTask.Result.Success ? purchaseTask.Result.Data : null;
            vm.PaymentSummary = paymentTask.Result.Success ? paymentTask.Result.Data : null;
            vm.ClientSummary = clientTask.Result.Success ? clientTask.Result.Data : null;
            vm.CommissionSummary = commissionTask.Result.Success ? commissionTask.Result.Data : null;
            vm.PeriodTotals = periodTask.Result.Success ? periodTask.Result.Data : null;
            vm.AgentCounts = agentCountsTask.Result.Success ? agentCountsTask.Result.Data : null;
            vm.TopUnderwriters = underwriterTask.Result.Success ? underwriterTask.Result.Data ?? new() : new();
            vm.ProductSales = productTask.Result.Success ? productTask.Result.Data ?? new() : new();
            vm.MonthlyTrend = trendTask.Result.Success ? trendTask.Result.Data ?? new() : new();
            vm.TopAgents = topAgentsTask.Result.Success ? topAgentsTask.Result.Data ?? new() : new();
        }

        return View(vm);
    }

    [AllowAnonymous]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}

public class ErrorViewModel
{
    public string? RequestId { get; set; }
    public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
}
