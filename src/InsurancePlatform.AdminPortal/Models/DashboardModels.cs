namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.PurchaseDashboardSummary - GET /api/purchases/summary's response shape.</summary>
public class PurchaseDashboardSummary
{
    public long ActiveCount { get; set; }
    public long ExpiredCount { get; set; }
    public long CancelledCount { get; set; }
    public long PaymentPendingCount { get; set; }
    public long PaymentPaidCount { get; set; }
    public long PaymentFailedCount { get; set; }
    public long TotalCount { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.PaymentDashboardSummary - GET /api/payments/summary's response shape.</summary>
public class PaymentDashboardSummary
{
    public long PendingCount { get; set; }
    public long SuccessCount { get; set; }
    public long FailedCount { get; set; }
    public long TotalCount { get; set; }
    public decimal TotalCollected { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.ClientDashboardSummary - GET /api/clients/summary's response shape.</summary>
public class ClientDashboardSummary
{
    public long TotalCount { get; set; }
    public long NewThisMonthCount { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.AgentCommissionDashboardSummary - GET /api/agentcommissions/summary's response shape (platform-wide, SA/AA/SP only).</summary>
public class AgentCommissionDashboardSummary
{
    public decimal TotalAccrued { get; set; }
    public decimal TotalWithdrawn { get; set; }
    public decimal AvailableBalance { get; set; }
    public long PendingWithdrawalCount { get; set; }
    public decimal PendingWithdrawalAmount { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.PurchasePeriodTotals - GET /api/purchases/period-totals's response shape. Back-office only.</summary>
public class PurchasePeriodTotals
{
    public long TodayCount { get; set; }
    public decimal TodayPremiumTotal { get; set; }
    public long MonthCount { get; set; }
    public decimal MonthPremiumTotal { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.UnderwriterSalesSummary - GET /api/purchases/by-underwriter's row shape. Back-office only.</summary>
public class UnderwriterSalesSummary
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.ProductSalesSummary - GET /api/purchases/by-product's row shape. Back-office only.</summary>
public class ProductSalesSummary
{
    public long ProductId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.MonthlyTrendPoint - GET /api/purchases/monthly-trend's row shape (always 6 rows). Back-office only.</summary>
public class MonthlyTrendPoint
{
    public string YearMonth { get; set; } = string.Empty;
    public string MonthLabel { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.TopAgentSummary - GET /api/purchases/top-agents's row shape. Back-office only.</summary>
public class TopAgentSummary
{
    public long AgentUserId { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public long PurchaseCount { get; set; }
    public decimal PremiumTotal { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.AgentCounts - GET /api/staff/agent-counts's response shape. Back-office only.</summary>
public class AgentCounts
{
    public long TotalAgentCount { get; set; }
    public long ActiveAgentCount { get; set; }
}

/// <summary>
/// Home/Index's view model - which properties get populated depends on the
/// signed-in user's role (see HomeController.Index):
///   - SuperAdmin/AgentAdmin/SupportAgent (the QuoteBackoffice + Commissions
///     back-office roles): QuoteRequestSummary, PurchaseSummary,
///     PaymentSummary, ClientSummary and CommissionSummary are all
///     platform-wide totals; MyCommissionBalance stays null (that widget is
///     Agent-only - back-office roles don't personally earn commission).
///   - Agent: QuoteRequestSummary and CommissionSummary stay null (both
///     back-office-only endpoints on the API side - an Agent's JWT gets a
///     403 if HomeController even tried), PurchaseSummary/PaymentSummary/
///     ClientSummary are scoped to just that agent's own purchases/payments/
///     clients (the API applies this scoping automatically based on the
///     caller's role, not a query param AdminPortal has to pass), and
///     MyCommissionBalance is that agent's own available balance.
/// The view checks each property for null and renders only what's there,
/// rather than HomeController building a different ViewModel type or
/// separate .cshtml per role - one view, role-aware sections.
/// </summary>
public class DashboardViewModel
{
    public string RoleCode { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;

    public List<QuoteRequestProductSummary>? QuoteRequestSummary { get; set; }
    public PurchaseDashboardSummary? PurchaseSummary { get; set; }
    public PaymentDashboardSummary? PaymentSummary { get; set; }
    public ClientDashboardSummary? ClientSummary { get; set; }
    public AgentCommissionDashboardSummary? CommissionSummary { get; set; }

    /// <summary>Agent's own available balance (GET /api/agentcommissions/me/balance) - null for every other role.</summary>
    public decimal? MyCommissionBalance { get; set; }

    // ── Back-office-only widgets (null for Agent - these six endpoints are
    // all SA/AA/SP-restricted on the API side, so HomeController never even
    // calls them for an Agent caller). ──
    public PurchasePeriodTotals? PeriodTotals { get; set; }
    public AgentCounts? AgentCounts { get; set; }
    public List<UnderwriterSalesSummary>? TopUnderwriters { get; set; }
    public List<ProductSalesSummary>? ProductSales { get; set; }
    public List<MonthlyTrendPoint>? MonthlyTrend { get; set; }
    public List<TopAgentSummary>? TopAgents { get; set; }
}
