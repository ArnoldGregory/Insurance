using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class PaymentRepository : IPaymentRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public PaymentRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(
        long purchaseId, decimal amount, string method, string? payerPhone, string? transactionReference,
        string actorType, long actorId)
    {
        var paymentIdParam = new MySqlParameter("o_payment_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_amount", amount),
            new("p_method", method),
            new("p_payer_phone", (object?)payerPhone ?? DBNull.Value),
            new("p_transaction_reference", (object?)transactionReference ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            paymentIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Payment_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = paymentIdParam.Value is null or DBNull ? null : Convert.ToInt64(paymentIdParam.Value)
        };
    }

    public Task<StoredProcResult> UpdateStatusAsync(long paymentId, string status, string? transactionReference, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_payment_id", paymentId),
            new("p_status", status),
            new("p_transaction_reference", (object?)transactionReference ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Payment_UpdateStatus", parameters);
    }

    public Task<StoredProcResult> SetGatewayReferenceAsync(long paymentId, string gatewayReference)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_payment_id", paymentId),
            new("p_gateway_reference", gatewayReference)
        };

        return _executor.ExecuteAsync("usp_Payment_SetGatewayReference", parameters);
    }

    public async Task<StoredProcResult<long?>> ResolveByGatewayReferenceAsync(
        string gatewayReference, string status, string? mpesaReceipt, string actorType, long? actorId)
    {
        var paymentIdParam = new MySqlParameter("o_payment_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var notProcessedParam = new MySqlParameter("o_not_processed", MySqlDbType.Int32) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_gateway_reference", gatewayReference),
            new("p_status", status),
            new("p_transaction_reference", (object?)mpesaReceipt ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", (object?)actorId ?? DBNull.Value),
            paymentIdParam,
            notProcessedParam
        };

        var result = await _executor.ExecuteAsync("usp_Payment_ResolveByGatewayReference", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = paymentIdParam.Value is null or DBNull ? null : Convert.ToInt64(paymentIdParam.Value)
        };
    }

    public async Task<StoredProcResult<long?>> ResolveByTransactionReferenceAsync(
        string transactionReference, string status, string? mpesaReceipt, string actorType, long? actorId)
    {
        var paymentIdParam = new MySqlParameter("o_payment_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var notProcessedParam = new MySqlParameter("o_not_processed", MySqlDbType.Int32) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_transaction_reference", transactionReference),
            new("p_status", status),
            new("p_mpesa_receipt", (object?)mpesaReceipt ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", (object?)actorId ?? DBNull.Value),
            paymentIdParam,
            notProcessedParam
        };

        var result = await _executor.ExecuteAsync("usp_Payment_ResolveByTransactionReference", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = paymentIdParam.Value is null or DBNull ? null : Convert.ToInt64(paymentIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<Payment>>> GetByPurchaseAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };
        return _executor.ExecuteQueryAsync("usp_Payment_GetByPurchase", parameters, MapRow);
    }

    public async Task<StoredProcResult<PaymentDashboardSummary>> GetSummaryAsync(long? purchasedByUserId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_purchased_by_user_id", (object?)purchasedByUserId ?? DBNull.Value)
        };

        var result = await _executor.ExecuteQuerySingleAsync("usp_Payment_GetSummary", parameters, MapSummaryStatsRow);

        return new StoredProcResult<PaymentDashboardSummary>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new PaymentDashboardSummary()
        };
    }

    private static Payment MapRow(MySqlDataReader reader)
    {
        return new Payment
        {
            PaymentId = reader.GetInt64("payment_id"),
            PurchaseId = reader.GetInt64("purchase_id"),
            Amount = reader.GetDecimal("amount"),
            Method = reader.GetString("method"),
            PayerPhone = reader.IsDBNull(reader.GetOrdinal("payer_phone")) ? null : reader.GetString("payer_phone"),
            TransactionReference = reader.IsDBNull(reader.GetOrdinal("transaction_reference")) ? null : reader.GetString("transaction_reference"),
            GatewayReference = reader.IsDBNull(reader.GetOrdinal("gateway_reference")) ? null : reader.GetString("gateway_reference"),
            Status = reader.GetString("status"),
            InitiatedOn = reader.GetDateTime("initiated_on"),
            CompletedOn = reader.IsDBNull(reader.GetOrdinal("completed_on")) ? null : reader.GetDateTime("completed_on")
        };
    }

    // pending/success/failed_count come from SUM(boolean-expression) -
    // Convert.ToInt64 tolerates whatever numeric CLR type MySqlConnector
    // hands back for that, same reasoning as PurchaseRepository's own
    // MapSummaryStatsRow. total_collected is a genuine DECIMAL(18,2) sum,
    // read with Convert.ToDecimal for the same "don't assume exact type" reason.
    private static PaymentDashboardSummary MapSummaryStatsRow(MySqlDataReader reader)
    {
        return new PaymentDashboardSummary
        {
            PendingCount = Convert.ToInt64(reader["pending_count"]),
            SuccessCount = Convert.ToInt64(reader["success_count"]),
            FailedCount = Convert.ToInt64(reader["failed_count"]),
            TotalCount = Convert.ToInt64(reader["total_count"]),
            TotalCollected = Convert.ToDecimal(reader["total_collected"])
        };
    }
}
