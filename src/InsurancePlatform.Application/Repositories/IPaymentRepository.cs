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

    /// <summary>
    /// Wraps usp_Payment_SetGatewayReference - persists the gateway's own
    /// transaction id (e.g. Daraja CheckoutRequestID) against a payment
    /// right after an STK push is accepted, so the later webhook can find
    /// that payment by reference alone.
    /// </summary>
    Task<StoredProcResult> SetGatewayReferenceAsync(long paymentId, string gatewayReference);

    /// <summary>
    /// Wraps usp_Payment_ResolveByGatewayReference - idempotent webhook
    /// resolution keyed on the payment gateway's CheckoutRequestID. Returns
    /// the resolved payment_id (null if no payment matched).
    /// </summary>
    Task<StoredProcResult<long?>> ResolveByGatewayReferenceAsync(
        string gatewayReference, string status, string? mpesaReceipt, string actorType, long? actorId);

    /// <summary>
    /// Wraps usp_Payment_ResolveByTransactionReference - idempotent webhook
    /// resolution keyed on transaction_reference (C2B Paybill BillRefNumber).
    /// Returns the resolved payment_id (null if no payment matched).
    /// </summary>
    Task<StoredProcResult<long?>> ResolveByTransactionReferenceAsync(
        string transactionReference, string status, string? mpesaReceipt, string actorType, long? actorId);

    Task<StoredProcResult<List<Payment>>> GetByPurchaseAsync(long purchaseId);

    /// <summary>
    /// Wraps usp_Payment_GetSummary - dashboard stat-card counts by status
    /// plus total amount collected. purchasedByUserId scopes through the
    /// owning Purchase's purchased_by_user_id, same convention as
    /// IPurchaseRepository.GetSummaryAsync (null = platform-wide).
    /// </summary>
    Task<StoredProcResult<PaymentDashboardSummary>> GetSummaryAsync(long? purchasedByUserId);
}
