using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class PricingRepository : IPricingRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public PricingRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> SetTpoPriceAsync(
        long underwriterId, long vehicleClassId, long periodId, string? carryCapacity,
        decimal? tonnage, decimal price, DateTime? effectiveFrom, long actorId)
    {
        var tpoPriceIdParam = new MySqlParameter("o_tpo_price_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_vehicle_class_id", vehicleClassId),
            new("p_period_id", periodId),
            new("p_carry_capacity", (object?)carryCapacity ?? DBNull.Value),
            new("p_tonnage", (object?)tonnage ?? DBNull.Value),
            new("p_price", price),
            new("p_effective_from", (object?)effectiveFrom ?? DBNull.Value),
            new("p_actor_id", actorId),
            tpoPriceIdParam
        };

        var result = await _executor.ExecuteAsync("usp_TpoPriceMapping_SetPrice", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = tpoPriceIdParam.Value is null or DBNull ? null : Convert.ToInt64(tpoPriceIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<TpoPriceOption>>> GetTpoPriceOptionsAsync(
        long vehicleClassId, long periodId, string? carryCapacity, decimal? tonnage)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_vehicle_class_id", vehicleClassId),
            new("p_period_id", periodId),
            new("p_carry_capacity", (object?)carryCapacity ?? DBNull.Value),
            new("p_tonnage", (object?)tonnage ?? DBNull.Value)
        };

        return _executor.ExecuteQueryAsync("usp_TpoPriceMapping_GetOptions", parameters, MapTpoPriceOptionRow);
    }

    public async Task<StoredProcResult<TpoPriceMappingListPage>> GetTpoPriceListAsync(
        long? underwriterId, long? vehicleClassId, bool? activeOnly, int pageNumber, int pageSize)
    {
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value),
            new("p_vehicle_class_id", (object?)vehicleClassId ?? DBNull.Value),
            new("p_active_only", (object?)activeOnly ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        var result = await _executor.ExecuteQueryAsync("usp_TpoPriceMapping_GetList", parameters, MapTpoPriceRow);

        var page = new TpoPriceMappingListPage
        {
            TotalCount = totalCountParam.Value is null or DBNull ? 0 : Convert.ToInt64(totalCountParam.Value),
            Items = result.Data ?? new List<TpoPriceMapping>()
        };

        return new StoredProcResult<TpoPriceMappingListPage>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = page
        };
    }

    public async Task<StoredProcResult<long?>> SetComprehensiveRateAsync(
        long underwriterId, long vehicleClassId, decimal baseRatePercent, decimal minPremium,
        DateTime? effectiveFrom, long actorId)
    {
        var formulaIdParam = new MySqlParameter("o_formula_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_vehicle_class_id", vehicleClassId),
            new("p_base_rate_percent", baseRatePercent),
            new("p_min_premium", minPremium),
            new("p_effective_from", (object?)effectiveFrom ?? DBNull.Value),
            new("p_actor_id", actorId),
            formulaIdParam
        };

        var result = await _executor.ExecuteAsync("usp_ComprehensiveRateFormula_SetRate", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = formulaIdParam.Value is null or DBNull ? null : Convert.ToInt64(formulaIdParam.Value)
        };
    }

    public async Task<StoredProcResult<long?>> AddComprehensiveFactorAsync(
        long formulaId, string factorType, decimal factorPercent, long actorId)
    {
        var factorIdParam = new MySqlParameter("o_factor_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_formula_id", formulaId),
            new("p_factor_type", factorType),
            new("p_factor_percent", factorPercent),
            new("p_actor_id", actorId),
            factorIdParam
        };

        var result = await _executor.ExecuteAsync("usp_ComprehensiveRateFactor_Add", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = factorIdParam.Value is null or DBNull ? null : Convert.ToInt64(factorIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<ComprehensiveRateFactor>>> GetComprehensiveFactorsByFormulaAsync(long formulaId)
    {
        var parameters = new List<MySqlParameter> { new("p_formula_id", formulaId) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveRateFactor_GetListByFormula", parameters, MapFactorRow);
    }

    public async Task<StoredProcResult<ComprehensivePremiumResult?>> CalculateComprehensivePremiumAsync(
        long underwriterId, long vehicleClassId, decimal vehicleValue)
    {
        var formulaIdParam = new MySqlParameter("o_formula_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var effectiveRateParam = new MySqlParameter("o_effective_rate_percent", MySqlDbType.Decimal) { Direction = ParameterDirection.Output };
        var premiumParam = new MySqlParameter("o_premium", MySqlDbType.Decimal) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_underwriter_id", underwriterId),
            new("p_vehicle_class_id", vehicleClassId),
            new("p_vehicle_value", vehicleValue),
            formulaIdParam,
            effectiveRateParam,
            premiumParam
        };

        var result = await _executor.ExecuteAsync("usp_ComprehensiveRateFormula_CalculatePremium", parameters);

        ComprehensivePremiumResult? premiumResult = null;
        if (result.IsSuccess)
        {
            premiumResult = new ComprehensivePremiumResult
            {
                FormulaId = Convert.ToInt64(formulaIdParam.Value),
                EffectiveRatePercent = Convert.ToDecimal(effectiveRateParam.Value),
                Premium = Convert.ToDecimal(premiumParam.Value)
            };
        }

        return new StoredProcResult<ComprehensivePremiumResult?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = premiumResult
        };
    }

    private static TpoPriceOption MapTpoPriceOptionRow(MySqlDataReader reader)
    {
        return new TpoPriceOption
        {
            TpoPriceId = reader.GetInt64("tpo_price_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            Price = reader.GetDecimal("price")
        };
    }

    private static TpoPriceMapping MapTpoPriceRow(MySqlDataReader reader)
    {
        return new TpoPriceMapping
        {
            TpoPriceId = reader.GetInt64("tpo_price_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            VehicleClassId = reader.GetInt64("vehicle_class_id"),
            VehicleClassName = reader.GetString("vehicle_class_name"),
            PeriodId = reader.GetInt64("period_id"),
            PeriodName = reader.GetString("period_name"),
            CarryCapacity = reader.IsDBNull(reader.GetOrdinal("carry_capacity")) ? null : reader.GetString("carry_capacity"),
            Tonnage = reader.IsDBNull(reader.GetOrdinal("tonnage")) ? null : reader.GetDecimal("tonnage"),
            Price = reader.GetDecimal("price"),
            EffectiveFrom = reader.GetDateTime("effective_from"),
            EffectiveTo = reader.IsDBNull(reader.GetOrdinal("effective_to")) ? null : reader.GetDateTime("effective_to"),
            IsActive = reader.GetBoolean("is_active")
        };
    }

    private static ComprehensiveRateFactor MapFactorRow(MySqlDataReader reader)
    {
        return new ComprehensiveRateFactor
        {
            FactorId = reader.GetInt64("factor_id"),
            FormulaId = reader.GetInt64("formula_id"),
            FactorType = reader.GetString("factor_type"),
            FactorPercent = reader.GetDecimal("factor_percent")
        };
    }

    public Task<StoredProcResult<List<ComprehensiveRateBandOption>>> GetComprehensiveRateBandOptionsAsync(decimal vehicleValue)
    {
        var parameters = new List<MySqlParameter> { new("p_vehicle_value", vehicleValue) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveRateBand_GetOptions", parameters, MapRateBandOptionRow);
    }

    public Task<StoredProcResult<List<ComprehensiveBenefitItem>>> GetComprehensiveBenefitsAsync(long underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", underwriterId) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveBenefit_GetList", parameters, MapBenefitRow);
    }

    private static ComprehensiveRateBandOption MapRateBandOptionRow(MySqlDataReader reader)
    {
        return new ComprehensiveRateBandOption
        {
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            RatePercent = reader.GetDecimal("rate_percent"),
            MinPremium = reader.GetDecimal("min_premium"),
            ValueMin = reader.GetDecimal("value_min"),
            ValueMax = reader.GetDecimal("value_max"),
            BasePremium = reader.GetDecimal("base_premium"),
            PvtAmount = reader.GetDecimal("pvt_amount"),
            TotalPremium = reader.GetDecimal("total_premium")
        };
    }

    public Task<StoredProcResult<List<LiabilityLimitItem>>> GetLiabilityLimitsAsync(long underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", underwriterId) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveLiabilityLimit_GetByUnderwriter", parameters, MapLiabilityLimitRow);
    }

    private static ComprehensiveBenefitItem MapBenefitRow(MySqlDataReader reader)
    {
        return new ComprehensiveBenefitItem
        {
            BenefitId = reader.GetInt64("benefit_id"),
            BenefitCode = reader.GetString("benefit_code"),
            BenefitName = reader.GetString("benefit_name"),
            DefaultPrice = reader.GetDecimal("default_price"),
            IsIncludedInBase = reader.GetBoolean("is_included_in_base"),
            Description = reader.IsDBNull(reader.GetOrdinal("description")) ? null : reader.GetString("description"),
            DisplayOrder = reader.GetInt32("display_order")
        };
    }

    private static LiabilityLimitItem MapLiabilityLimitRow(MySqlDataReader reader)
    {
        return new LiabilityLimitItem
        {
            LiabilityLimitId = reader.GetInt64("liability_limit_id"),
            LimitName = reader.GetString("limit_name"),
            LimitValue = reader.GetString("limit_value"),
            DisplayOrder = reader.GetInt32("display_order")
        };
    }

    public Task<StoredProcResult<List<RateBandAdminItem>>> GetRateBandsAllAsync(long? underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveRateBand_GetAll", parameters, MapRateBandAdminRow);
    }

    public async Task<StoredProcResult<long?>> UpsertRateBandAsync(long? rateBandId, long underwriterId, decimal minValue, decimal maxValue, decimal ratePercent, decimal minPremium, int displayOrder)
    {
        var outParam = new MySqlParameter("o_result_code", MySqlDbType.Int32) { Direction = ParameterDirection.Output };
        var msgParam = new MySqlParameter("o_result_message", MySqlDbType.VarChar, 500) { Direction = ParameterDirection.Output };
        var parameters = new List<MySqlParameter>
        {
            new("p_rate_band_id", (object?)rateBandId ?? DBNull.Value),
            new("p_underwriter_id", underwriterId),
            new("p_min_value", minValue),
            new("p_max_value", maxValue),
            new("p_rate_percent", ratePercent),
            new("p_min_premium", minPremium),
            new("p_display_order", displayOrder),
            outParam, msgParam
        };
        var result = await _executor.ExecuteAsync("usp_ComprehensiveRateBand_Upsert", parameters);
        return new StoredProcResult<long?> { ResultCode = result.ResultCode, ResultMessage = result.ResultMessage };
    }

    public async Task<StoredProcResult> DeleteRateBandAsync(long rateBandId)
    {
        var parameters = new List<MySqlParameter> { new("p_rate_band_id", rateBandId) };
        return await _executor.ExecuteAsync("usp_ComprehensiveRateBand_Delete", parameters);
    }

    public Task<StoredProcResult<List<BenefitAdminItem>>> GetBenefitsAllAsync(long? underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveBenefit_GetAll", parameters, MapBenefitAdminRow);
    }

    public async Task<StoredProcResult> UpsertBenefitAsync(long? benefitId, long underwriterId, string benefitCode, string benefitName, decimal defaultPrice, bool isIncludedInBase, string? description, int displayOrder)
    {
        var outParam = new MySqlParameter("o_result_code", MySqlDbType.Int32) { Direction = ParameterDirection.Output };
        var msgParam = new MySqlParameter("o_result_message", MySqlDbType.VarChar, 500) { Direction = ParameterDirection.Output };
        var parameters = new List<MySqlParameter>
        {
            new("p_benefit_id", (object?)benefitId ?? DBNull.Value),
            new("p_underwriter_id", underwriterId),
            new("p_benefit_code", benefitCode),
            new("p_benefit_name", benefitName),
            new("p_default_price", defaultPrice),
            new("p_is_included_in_base", isIncludedInBase ? 1 : 0),
            new("p_description", (object?)description ?? DBNull.Value),
            new("p_display_order", displayOrder),
            outParam, msgParam
        };
        return await _executor.ExecuteAsync("usp_ComprehensiveBenefit_Upsert", parameters);
    }

    public async Task<StoredProcResult> DeleteBenefitAsync(long benefitId)
    {
        var parameters = new List<MySqlParameter> { new("p_benefit_id", benefitId) };
        return await _executor.ExecuteAsync("usp_ComprehensiveBenefit_Delete", parameters);
    }

    public Task<StoredProcResult<List<LiabilityLimitAdminItem>>> GetLiabilityLimitsAllAsync(long? underwriterId)
    {
        var parameters = new List<MySqlParameter> { new("p_underwriter_id", (object?)underwriterId ?? DBNull.Value) };
        return _executor.ExecuteQueryAsync("usp_ComprehensiveLiabilityLimit_GetAll", parameters, MapLiabilityLimitAdminRow);
    }

    public async Task<StoredProcResult> UpsertLiabilityLimitAsync(long? liabilityLimitId, long underwriterId, string limitName, string limitValue, int displayOrder)
    {
        var outParam = new MySqlParameter("o_result_code", MySqlDbType.Int32) { Direction = ParameterDirection.Output };
        var msgParam = new MySqlParameter("o_result_message", MySqlDbType.VarChar, 500) { Direction = ParameterDirection.Output };
        var parameters = new List<MySqlParameter>
        {
            new("p_liability_limit_id", (object?)liabilityLimitId ?? DBNull.Value),
            new("p_underwriter_id", underwriterId),
            new("p_limit_name", limitName),
            new("p_limit_value", limitValue),
            new("p_display_order", displayOrder),
            outParam, msgParam
        };
        return await _executor.ExecuteAsync("usp_ComprehensiveLiabilityLimit_Upsert", parameters);
    }

    public async Task<StoredProcResult> DeleteLiabilityLimitAsync(long liabilityLimitId)
    {
        var parameters = new List<MySqlParameter> { new("p_liability_limit_id", liabilityLimitId) };
        return await _executor.ExecuteAsync("usp_ComprehensiveLiabilityLimit_Delete", parameters);
    }

    private static RateBandAdminItem MapRateBandAdminRow(MySqlDataReader reader)
    {
        return new RateBandAdminItem
        {
            BandId = reader.GetInt64("band_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            ValueMin = reader.GetDecimal("value_min"),
            ValueMax = reader.GetDecimal("value_max"),
            RatePercent = reader.GetDecimal("rate_percent"),
            MinPremium = reader.GetDecimal("min_premium"),
            EffectiveFrom = reader.GetDateTime("effective_from"),
            EffectiveTo = reader.IsDBNull(reader.GetOrdinal("effective_to")) ? null : reader.GetDateTime("effective_to"),
            IsActive = reader.GetBoolean("is_active")
        };
    }

    private static BenefitAdminItem MapBenefitAdminRow(MySqlDataReader reader)
    {
        return new BenefitAdminItem
        {
            BenefitId = reader.GetInt64("benefit_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            BenefitCode = reader.GetString("benefit_code"),
            BenefitName = reader.GetString("benefit_name"),
            DefaultPrice = reader.GetDecimal("default_price"),
            IsIncludedInBase = reader.GetBoolean("is_included_in_base"),
            Description = reader.IsDBNull(reader.GetOrdinal("description")) ? null : reader.GetString("description"),
            DisplayOrder = reader.GetInt32("display_order"),
            IsActive = reader.GetBoolean("is_active")
        };
    }

    private static LiabilityLimitAdminItem MapLiabilityLimitAdminRow(MySqlDataReader reader)
    {
        return new LiabilityLimitAdminItem
        {
            LiabilityLimitId = reader.GetInt64("liability_limit_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            LimitName = reader.GetString("limit_name"),
            LimitValue = reader.GetString("limit_value"),
            DisplayOrder = reader.GetInt32("display_order")
        };
    }

    public Task<StoredProcResult<List<PurchaseTimelineEvent>>> GetPurchaseTimelineAsync(long purchaseId)
    {
        var parameters = new List<MySqlParameter> { new("p_purchase_id", purchaseId) };
        return _executor.ExecuteQueryAsync("usp_Purchase_GetTimeline", parameters, MapTimelineRow);
    }

    private static PurchaseTimelineEvent MapTimelineRow(MySqlDataReader reader)
    {
        return new PurchaseTimelineEvent
        {
            EventType = reader.GetString("event_type"),
            StepOrder = reader.GetInt32("step_order"),
            RefId = reader.GetInt64("ref_id"),
            EventTime = reader.GetDateTime("event_time"),
            EventDataJson = reader.GetString("event_data")
        };
    }
}
