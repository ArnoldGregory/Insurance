using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IPaymentRepository
{
    Task<StoredProcResult<long?>> CreateAsync(
        long purchaseId, decimal amount, string method, string? payerPhone, string? transactionReference,
        string actorType, long actorId);

    Task<StoredProcResult> UpdateStatusAsync(
        long paymentId, string status, string? transactionReference, string actorType, long actorId);

    Task<StoredProcResult<List<Payment>>> GetByPurchaseAsync(long purchaseId);

    /// <summary>
    /// Wraps usp_Payment_GetSummary - dashboard stat-card counts by status
    /// plus total amount collected. purchasedByUserId scopes through the
    /// owning Purchase's purchased_by_user_id, same convention as
    /// IPurchaseRepository.GetSummaryAsync (null = platform-wide).
    /// </summary>
    Task<StoredProcResult<PaymentDashboardSummary>> GetSummaryAsync(long? purchasedByUserId);
}
