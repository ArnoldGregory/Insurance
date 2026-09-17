using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class PurchaseRepository : IPurchaseRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public PurchaseRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<PurchaseCreateResult?>> CreateAsync(
        long productId, long clientId, long? purchasedByUserId, long? channelServiceAccountId,
        long underwriterId, long? quoteOfferId, decimal premiumAmount, long periodId, DateTime startDate,
        string? policyNumber, long? vehicleId, decimal? vehicleValue, decimal? tonnage,
        long? licensedToCarry, string? antiTheft, string? risk, decimal? snapshotAmount)
    {
        var purchaseIdParam = new MySqlParameter("o_purchase_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var policyNumberParam = new MySqlParameter("o_policy_number", MySqlDbType.VarChar, 50) { Direction = ParameterDirection.Output };
        var endDateParam = new MySqlParameter("o_end_date", MySqlDbType.Date) { Direction = ParameterDirection.Output };
        var accountNumberParam = new MySqlParameter("o_account_number", MySqlDbType.VarChar, 120) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_product_id", productId),
            new("p_client_id", clientId),
            new("p_purchased_by_user_id", (object?)purchasedByUserId ?? DBNull.Value),
            new("p_channel_service_account_id", (object?)channelServiceAccountId ?? DBNull.Value),
            new("p_underwriter_id", underwriterId),
            new("p_quote_offer_id", (object?)quoteOfferId ?? DBNull.Value),
            new("p_premium_amount", premiumAmount),
            new("p_period_id", periodId),
            new("p_start_date", startDate),
            new("p_policy_number", (object?)policyNumber ?? DBNull.Value),
            new("p_vehicle_id", (object?)vehicleId ?? DBNull.Value),
            new("p_vehicle_value", (object?)vehicleValue ?? DBNull.Value),
            new("p_tonnage", (object?)tonnage ?? DBNull.Value),
            new("p_licensedtocarry", (object?)licensedToCarry ?? DBNull.Value),
            new("p_antitheft", (object?)antiTheft ?? DBNull.Value),
            new("p_risk", (object?)risk ?? DBNull.Value),
            new("p_snapshot_amount", (object?)snapshotAmount ?? DBNull.Value),
            purchaseIdParam,
            policyNumberParam,
            endDateParam,
            accountNumberParam
        };

        var result = await _executor.ExecuteAsync("usp_Purchase_Create", parameters);

        PurchaseCreateResult? createResult = null;
        if (result.IsSuccess)
        {
            createResult = new PurchaseCreateResult
            {
                PurchaseId = Convert.ToInt64(purchaseIdParam.Value),
                PolicyNumber = policyNumberParam.Value as string ?? string.Empty,
                EndDate = Convert.ToDateTime(endDateParam.Value),
                AccountNumber = accountNumberParam.Value as string ?? string.Empty
                // PaybillNumber is intentionally left blank here - it's a
                // fixed config value, not proc output, filled in by
                // PurchasesController.Create after this call returns.
            };
        }

        return new StoredProcResult<PurchaseCreateResult?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = createResult
        };
    }

    public Task<StoredProcResult<Purchase?>> GetByIdAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };

        // usp_Purchase_GetById returns two result sets (the purchase row,
        // then any VehiclePurchaseSnapshot rows) - see
        // IStoredProcedureExecutor.ExecuteQuerySingleWithChildrenAsync's own
        // doc comment for why this needs the two-result-set-aware call
        // instead of the plain ExecuteQuerySingleAsync every other GetById
        // in this project uses.
        return _executor.ExecuteQuerySingleWithChildrenAsync(
            "usp_Purchase_GetById", parameters, MapRow, MapSnapshotRow,
            (purchase, snapshots) => purchase.VehicleSnapshot = snapshots.Count > 0 ? snapshots[0] : null);
    }

    public Task<StoredProcResult<PurchaseDmvicData?>> GetDmvicDataAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };

        // usp_Purchase_GetDmvicData returns at most one row (the purchase
        // row with LEFT-JOINed vehicle defaults) - plain
        // ExecuteQuerySingleAsync is exactly the right call shape. When the
        // purchase doesn't exist the proc returns a non-zero result code
        // without emitting a result set, which surfaces as Data == null.
        return _executor.ExecuteQuerySingleAsync("usp_Purchase_GetDmvicData", parameters, MapDmvicDataRow);
    }

    public Task<StoredProcResult> SaveDmvicResultAsync(
        long purchaseId, string? ntsaCertificateNo, string? ntsaTransactionNo,
        string? email, string? certDownloadUrl, string? certData)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_ntsa_certificate_no", (object?)ntsaCertificateNo ?? DBNull.Value),
            new("p_ntsa_transaction_no", (object?)ntsaTransactionNo ?? DBNull.Value),
            new("p_email", (object?)email ?? DBNull.Value),
            new("p_cert_download_url", (object?)certDownloadUrl ?? DBNull.Value),
            new("p_cert_data", (object?)certData ?? DBNull.Value)
        };

        return _executor.ExecuteAsync("usp_Purchase_SaveDmvicResult", parameters);
    }

    public Task<StoredProcResult<VehicleCertificateDocument?>> GetVehicleCertificateDocumentAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };

        return _executor.ExecuteQuerySingleAsync(
            "usp_Purchase_GetVehicleCertificateDocument", parameters, MapVehicleCertificateDocumentRow);
    }

    public async Task<StoredProcResult<PurchaseListPage>> GetListAsync(
        long? clientId, long? purchasedByUserId, long? productId, long? underwriterId, string? status,
        string? paymentStatus, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize)
    {
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_purchased_by_user_id", (object?)purchasedByUserId ?? DBNull.Value),
            new("p_product_id", (object?)productId ?? DBNull.Value),
            new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value),
            new("p_status", (object?)status ?? DBNull.Value),
            new("p_payment_status", (object?)paymentStatus ?? DBNull.Value),
            new("p_date_from", (object?)dateFrom ?? DBNull.Value),
            new("p_date_to", (object?)dateTo ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        var result = await _executor.ExecuteQueryAsync("usp_Purchase_GetList", parameters, MapSummaryRow);

        var page = new PurchaseListPage
        {
            TotalCount = totalCountParam.Value is null or DBNull ? 0 : Convert.ToInt64(totalCountParam.Value),
            Items = result.Data ?? new List<PurchaseSummary>()
        };

        return new StoredProcResult<PurchaseListPage>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = page
        };
    }

    public Task<StoredProcResult> UpdateStatusAsync(long purchaseId, string status, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_status", status),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Purchase_UpdateStatus", parameters);
    }

    public Task<StoredProcResult> CompleteCertAsync(long purchaseId, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_purchase_id", purchaseId),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Purchase_CompleteCert", parameters);
    }

    public async Task<StoredProcResult<PurchaseDashboardSummary>> GetSummaryAsync(long? purchasedByUserId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_purchased_by_user_id", (object?)purchasedByUserId ?? DBNull.Value)
        };

        // usp_Purchase_GetSummary always returns exactly one row (a plain
        // aggregate, no GROUP BY) - ExecuteQuerySingleAsync reads at most
        // one row and hands back T?, so the ?? below covers only the
        // theoretical case of the proc itself failing (ResultCode != 0),
        // never "no purchases yet" (COUNT/SUM already return 0 for that).
        var result = await _executor.ExecuteQuerySingleAsync("usp_Purchase_GetSummary", parameters, MapSummaryStatsRow);

        return new StoredProcResult<PurchaseDashboardSummary>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new PurchaseDashboardSummary()
        };
    }

    private static Purchase MapRow(MySqlDataReader reader)
    {
        return new Purchase
        {
            PurchaseId = reader.GetInt64("purchase_id"),
            ProductId = reader.GetInt64("product_id"),
            ProductCode = reader.GetString("product_code"),
            ClientId = reader.GetInt64("client_id"),
            PurchasedByUserId = reader.IsDBNull(reader.GetOrdinal("purchased_by_user_id")) ? null : reader.GetInt64("purchased_by_user_id"),
            ChannelServiceAccountId = reader.IsDBNull(reader.GetOrdinal("channel_service_account_id")) ? null : reader.GetInt64("channel_service_account_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            QuoteOfferId = reader.IsDBNull(reader.GetOrdinal("quote_offer_id")) ? null : reader.GetInt64("quote_offer_id"),
            PremiumAmount = reader.GetDecimal("premium_amount"),
            PeriodId = reader.GetInt64("period_id"),
            PeriodName = reader.GetString("period_name"),
            StartDate = reader.GetDateTime("start_date"),
            EndDate = reader.GetDateTime("end_date"),
            PolicyNumber = reader.IsDBNull(reader.GetOrdinal("policy_number")) ? null : reader.GetString("policy_number"),
            PaymentStatus = reader.GetString("payment_status"),
            Status = reader.GetString("status"),
            CreatedOn = reader.GetDateTime("created_on"),
            CertificateStatus = reader.IsDBNull(reader.GetOrdinal("certificate_status")) ? string.Empty : reader.GetString("certificate_status"),
            CertificateGeneratedOn = reader.IsDBNull(reader.GetOrdinal("cert_generated_on")) ? null : reader.GetDateTime("cert_generated_on"),
            CertificateNumber = reader.IsDBNull(reader.GetOrdinal("certificate_number")) ? null : reader.GetString("certificate_number"),
            NtsaCertificateNo = reader.IsDBNull(reader.GetOrdinal("ntsa_certificate_no")) ? null : reader.GetString("ntsa_certificate_no"),
            NtsaTransactionNo = reader.IsDBNull(reader.GetOrdinal("ntsa_transaction_no")) ? null : reader.GetString("ntsa_transaction_no"),
            NtsaIssuedOn = reader.IsDBNull(reader.GetOrdinal("ntsa_issued_on")) ? null : reader.GetDateTime("ntsa_issued_on"),
            ClientName = reader.IsDBNull(reader.GetOrdinal("client_name")) ? null : reader.GetString("client_name"),
            ClientIdNo = reader.IsDBNull(reader.GetOrdinal("client_id_no")) ? null : reader.GetString("client_id_no"),
            ClientPhone = reader.IsDBNull(reader.GetOrdinal("client_phone")) ? null : reader.GetString("client_phone"),
            ClientEmail = reader.IsDBNull(reader.GetOrdinal("client_email")) ? null : reader.GetString("client_email"),
            ProductName = reader.IsDBNull(reader.GetOrdinal("product_name")) ? null : reader.GetString("product_name"),
            VehicleRegNo = reader.IsDBNull(reader.GetOrdinal("vehicle_reg_no")) ? null : reader.GetString("vehicle_reg_no"),
            VehicleMake = reader.IsDBNull(reader.GetOrdinal("vehicle_make")) ? null : reader.GetString("vehicle_make"),
            VehicleModel = reader.IsDBNull(reader.GetOrdinal("vehicle_model")) ? null : reader.GetString("vehicle_model")
        };
    }

    private static VehiclePurchaseSnapshot MapSnapshotRow(MySqlDataReader reader)
    {
        return new VehiclePurchaseSnapshot
        {
            SnapshotId = reader.GetInt64("snapshot_id"),
            VehicleId = reader.GetInt64("vehicle_id"),
            VehicleValue = reader.IsDBNull(reader.GetOrdinal("vehicle_value")) ? null : reader.GetDecimal("vehicle_value"),
            Tonnage = reader.IsDBNull(reader.GetOrdinal("tonnage")) ? null : reader.GetDecimal("tonnage"),
            LicensedToCarry = reader.IsDBNull(reader.GetOrdinal("licensedtocarry")) ? null : reader.GetInt64("licensedtocarry"),
            AntiTheft = reader.IsDBNull(reader.GetOrdinal("antitheft")) ? null : reader.GetString("antitheft"),
            Risk = reader.IsDBNull(reader.GetOrdinal("risk")) ? null : reader.GetString("risk"),
            Amount = reader.IsDBNull(reader.GetOrdinal("amount")) ? null : reader.GetDecimal("amount")
        };
    }

    private static PurchaseDmvicData? MapDmvicDataRow(MySqlDataReader reader)
    {
        return new PurchaseDmvicData
        {
            PurchaseId = reader.GetInt64("purchase_id"),
            PolicyNumber = reader.IsDBNull(reader.GetOrdinal("policy_number")) ? null : reader.GetString("policy_number"),
            StartDate = reader.GetDateTime("start_date"),
            EndDate = reader.GetDateTime("end_date"),
            PremiumAmount = reader.GetDecimal("premium_amount"),
            CertificateNumber = reader.IsDBNull(reader.GetOrdinal("certificate_number")) ? null : reader.GetString("certificate_number"),
            NtsaCertificateNo = reader.IsDBNull(reader.GetOrdinal("ntsa_certificate_no")) ? null : reader.GetString("ntsa_certificate_no"),
            NtsaTransactionNo = reader.IsDBNull(reader.GetOrdinal("ntsa_transaction_no")) ? null : reader.GetString("ntsa_transaction_no"),
            Policyholder = reader.IsDBNull(reader.GetOrdinal("policyholder")) ? null : reader.GetString("policyholder"),
            ClientPhone = reader.IsDBNull(reader.GetOrdinal("client_phone")) ? null : reader.GetString("client_phone"),
            ClientEmail = reader.IsDBNull(reader.GetOrdinal("client_email")) ? null : reader.GetString("client_email"),
            KraPin = reader.IsDBNull(reader.GetOrdinal("kra_pin")) ? null : reader.GetString("kra_pin"),
            RegNo = reader.IsDBNull(reader.GetOrdinal("reg_no")) ? null : reader.GetString("reg_no"),
            Make = reader.IsDBNull(reader.GetOrdinal("make")) ? null : reader.GetString("make"),
            Model = reader.IsDBNull(reader.GetOrdinal("model")) ? null : reader.GetString("model"),
            ChassisNo = reader.IsDBNull(reader.GetOrdinal("chassis_no")) ? null : reader.GetString("chassis_no"),
            EngineNo = reader.IsDBNull(reader.GetOrdinal("engine_no")) ? null : reader.GetString("engine_no"),
            YearOfManufacture = reader.IsDBNull(reader.GetOrdinal("yearofmanufacture")) ? null : reader.GetInt32("yearofmanufacture"),
            PBodyType = reader.IsDBNull(reader.GetOrdinal("p_bodytype")) ? null : reader.GetString("p_bodytype"),
            VehicleType = reader.IsDBNull(reader.GetOrdinal("vehicle_type")) ? null : reader.GetString("vehicle_type"),
            VehicleValue = reader.IsDBNull(reader.GetOrdinal("vehicle_value")) ? null : reader.GetDecimal("vehicle_value"),
            LicensedToCarry = reader.IsDBNull(reader.GetOrdinal("licensedtocarry")) ? null : reader.GetInt64("licensedtocarry"),
            MemberCompanyId = reader.IsDBNull(reader.GetOrdinal("member_company_id")) ? null : reader.GetString("member_company_id"),
            UnderwriterName = reader.IsDBNull(reader.GetOrdinal("underwriter_name")) ? null : reader.GetString("underwriter_name")
        };
    }

    private static VehicleCertificateDocument MapVehicleCertificateDocumentRow(MySqlDataReader reader)
    {
        return new VehicleCertificateDocument
        {
            CertDocId = reader.GetInt64("cert_doc_id"),
            PurchaseId = reader.GetInt64("purchase_id"),
            TransactionNo = reader.IsDBNull(reader.GetOrdinal("transaction_no")) ? null : reader.GetString("transaction_no"),
            CertNo = reader.IsDBNull(reader.GetOrdinal("cert_no")) ? null : reader.GetString("cert_no"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            CertDownloadUrl = reader.IsDBNull(reader.GetOrdinal("cert_download_url")) ? null : reader.GetString("cert_download_url"),
            CertData = reader.IsDBNull(reader.GetOrdinal("cert_data")) ? null : reader.GetString("cert_data"),
            CertGenerated = reader.GetBoolean("cert_generated"),
            CertStatus = reader.IsDBNull(reader.GetOrdinal("cert_status")) ? null : reader.GetString("cert_status"),
            PolicyNumber = reader.IsDBNull(reader.GetOrdinal("policy_number")) ? null : reader.GetString("policy_number"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static PurchaseSummary MapSummaryRow(MySqlDataReader reader)
    {
        return new PurchaseSummary
        {
            PurchaseId = reader.GetInt64("purchase_id"),
            ProductId = reader.GetInt64("product_id"),
            ProductCode = reader.GetString("product_code"),
            ClientId = reader.GetInt64("client_id"),
            ClientName = reader.GetString("client_name"),
            PurchasedByUserId = reader.IsDBNull(reader.GetOrdinal("purchased_by_user_id")) ? null : reader.GetInt64("purchased_by_user_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            PremiumAmount = reader.GetDecimal("premium_amount"),
            PolicyNumber = reader.IsDBNull(reader.GetOrdinal("policy_number")) ? null : reader.GetString("policy_number"),
            PaymentStatus = reader.GetString("payment_status"),
            Status = reader.GetString("status"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    public async Task<StoredProcResult<PurchasePeriodTotals>> GetPeriodTotalsAsync()
    {
        var result = await _executor.ExecuteQuerySingleAsync(
            "usp_Purchase_GetPeriodTotals", new List<MySqlParameter>(), MapPeriodTotalsRow);

        return new StoredProcResult<PurchasePeriodTotals>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new PurchasePeriodTotals()
        };
    }

    public Task<StoredProcResult<List<UnderwriterSalesSummary>>> GetByUnderwriterAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Purchase_GetByUnderwriter", new List<MySqlParameter>(), MapUnderwriterSalesRow);
    }

    public Task<StoredProcResult<List<ProductSalesSummary>>> GetByProductAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Purchase_GetByProduct", new List<MySqlParameter>(), MapProductSalesRow);
    }

    public Task<StoredProcResult<List<MonthlyTrendPoint>>> GetMonthlyTrendAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Purchase_GetMonthlyTrend", new List<MySqlParameter>(), MapMonthlyTrendRow);
    }

    public Task<StoredProcResult<List<long>>> FindPendingCertCompletionAsync()
    {
        // usp_Purchase_FindPendingCertCompletion takes no IN params - the
        // worker scope is platform-wide by design (any PAID-but-not-generated
        // purchase gets picked up regardless of who sold it).
        return _executor.ExecuteQueryAsync(
            "usp_Purchase_FindPendingCertCompletion", new List<MySqlParameter>(), reader => reader.GetInt64("purchase_id"));
    }

    public Task<StoredProcResult<List<TopAgentSummary>>> GetTopAgentsAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Purchase_GetTopAgents", new List<MySqlParameter>(), MapTopAgentRow);
    }

    private static PurchasePeriodTotals MapPeriodTotalsRow(MySqlDataReader reader)
    {
        return new PurchasePeriodTotals
        {
            TodayCount = Convert.ToInt64(reader["today_count"]),
            TodayPremiumTotal = Convert.ToDecimal(reader["today_premium_total"]),
            MonthCount = Convert.ToInt64(reader["month_count"]),
            MonthPremiumTotal = Convert.ToDecimal(reader["month_premium_total"])
        };
    }

    private static UnderwriterSalesSummary MapUnderwriterSalesRow(MySqlDataReader reader)
    {
        return new UnderwriterSalesSummary
        {
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            PurchaseCount = Convert.ToInt64(reader["purchase_count"]),
            PremiumTotal = Convert.ToDecimal(reader["premium_total"])
        };
    }

    private static ProductSalesSummary MapProductSalesRow(MySqlDataReader reader)
    {
        return new ProductSalesSummary
        {
            ProductId = reader.GetInt64("product_id"),
            ProductCode = reader.GetString("product_code"),
            ProductName = reader.GetString("product_name"),
            PurchaseCount = Convert.ToInt64(reader["purchase_count"]),
            PremiumTotal = Convert.ToDecimal(reader["premium_total"])
        };
    }

    private static MonthlyTrendPoint MapMonthlyTrendRow(MySqlDataReader reader)
    {
        return new MonthlyTrendPoint
        {
            YearMonth = reader.GetString("year_month"),
            MonthLabel = reader.GetString("month_label"),
            PurchaseCount = Convert.ToInt64(reader["purchase_count"]),
            PremiumTotal = Convert.ToDecimal(reader["premium_total"])
        };
    }

    private static TopAgentSummary MapTopAgentRow(MySqlDataReader reader)
    {
        return new TopAgentSummary
        {
            AgentUserId = reader.GetInt64("agent_user_id"),
            AgentName = reader.GetString("agent_name"),
            PurchaseCount = Convert.ToInt64(reader["purchase_count"]),
            PremiumTotal = Convert.ToDecimal(reader["premium_total"])
        };
    }

    // Every count column here comes from SUM(boolean-expression) or
    // COUNT(*), which MySqlConnector can hand back as DECIMAL rather than
    // a plain integer type - Convert.ToInt64 (not GetInt64, which requires
    // an exact type match) tolerates whichever numeric CLR type actually
    // comes back, same reasoning as QuoteRequestRepository.MapSummaryRow.
    private static PurchaseDashboardSummary MapSummaryStatsRow(MySqlDataReader reader)
    {
        return new PurchaseDashboardSummary
        {
            ActiveCount = Convert.ToInt64(reader["active_count"]),
            ExpiredCount = Convert.ToInt64(reader["expired_count"]),
            CancelledCount = Convert.ToInt64(reader["cancelled_count"]),
            PaymentPendingCount = Convert.ToInt64(reader["payment_pending_count"]),
            PaymentPaidCount = Convert.ToInt64(reader["payment_paid_count"]),
            PaymentFailedCount = Convert.ToInt64(reader["payment_failed_count"]),
            TotalCount = Convert.ToInt64(reader["total_count"])
        };
    }
}
