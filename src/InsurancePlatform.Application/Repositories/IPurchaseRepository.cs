using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IPurchaseRepository
{
    // Mirrors usp_Purchase_Create's own IN param list one-for-one (17
    // params) rather than wrapping them in a request object - loose,
    // named-at-the-call-site parameters is this project's convention even
    // for wide procs (see ClientRepository.CreateAsync), and it keeps the
    // 1:1 mapping between this method and the proc signature obvious.
    Task<StoredProcResult<PurchaseCreateResult?>> CreateAsync(
        long productId, long clientId, long? purchasedByUserId, long? channelServiceAccountId,
        long underwriterId, long? quoteOfferId, decimal premiumAmount, long periodId, DateTime startDate,
        string? policyNumber, long? vehicleId, decimal? vehicleValue, decimal? tonnage,
        long? licensedToCarry, string? antiTheft, string? risk, decimal? snapshotAmount);

    Task<StoredProcResult<Purchase?>> GetByIdAsync(long purchaseId);

    // paymentStatus filters on Purchases.payment_status (PENDING/PAID) -
    // separate from status, which is the policy's own lifecycle
    // (ACTIVE/EXPIRED/CANCELLED). Pass paymentStatus="PENDING" for the
    // "payment not yet confirmed" queue - see usp_Purchase_GetList's own
    // doc comment for why this exists (no callback/background job resolves
    // payment_status automatically yet).
    Task<StoredProcResult<PurchaseListPage>> GetListAsync(
        long? clientId, long? purchasedByUserId, long? productId, long? underwriterId, string? status,
        string? paymentStatus, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize);

    Task<StoredProcResult> UpdateStatusAsync(long purchaseId, string status, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_Purchase_CompleteCert - the shared purchase-completion
    /// routine. Validates the purchase is PAID, flips certificate_status to
    /// GENERATED (with cert_generated_on), writes an AuditLog COMPLETE
    /// entry, and returns the "payment received - certificate will be
    /// emailed" confirmation. This is the exact code path a retry button
    /// AND a background take-over service both call so completion stays in
    /// one place. actorType is normalized to USER (from anything else the
    /// caller passes) inside the proc, because AuditLog.actor_type is
    /// CHECK-constrained.
    /// </summary>
    Task<StoredProcResult> CompleteCertAsync(long purchaseId, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_Purchase_GetSummary - dashboard stat-card counts (by
    /// status and payment_status), not a list. purchasedByUserId is the
    /// same optional scoping filter as GetListAsync's own param of the
    /// same name: null for a platform-wide rollup, an agent's own user_id
    /// for their own "how many policies have I sold" dashboard.
    /// </summary>
    Task<StoredProcResult<PurchaseDashboardSummary>> GetSummaryAsync(long? purchasedByUserId);

    /// <summary>Wraps usp_Purchase_GetPeriodTotals - the back-office dashboard's "Monthly Purchases"/"Daily Purchases" widgets. Always platform-wide.</summary>
    Task<StoredProcResult<PurchasePeriodTotals>> GetPeriodTotalsAsync();

    /// <summary>Wraps usp_Purchase_GetByUnderwriter - top 10 underwriters by premium written. Always platform-wide.</summary>
    Task<StoredProcResult<List<UnderwriterSalesSummary>>> GetByUnderwriterAsync();

    /// <summary>Wraps usp_Purchase_GetByProduct - every product's purchase count + premium total. Always platform-wide.</summary>
    Task<StoredProcResult<List<ProductSalesSummary>>> GetByProductAsync();

    /// <summary>Wraps usp_Purchase_GetMonthlyTrend - always exactly 6 rows (oldest to newest, zero-filled). Always platform-wide.</summary>
    Task<StoredProcResult<List<MonthlyTrendPoint>>> GetMonthlyTrendAsync();

    /// <summary>Wraps usp_Purchase_GetTopAgents - top 10 agents by policies sold. Always platform-wide.</summary>
    Task<StoredProcResult<List<TopAgentSummary>>> GetTopAgentsAsync();
}
