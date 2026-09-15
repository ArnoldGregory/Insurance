using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

// Covers both Motor pricing methods (Products.pricing_method): TPO's flat
// price-per-combination lookup, and Comprehensive's percentage-of-value
// formula. Grouped in one interface because they're the same conceptual
// job (turn vehicle attributes into a premium) even though the underlying
// tables/procs are shaped completely differently.
public interface IPricingRepository
{
    Task<StoredProcResult<long?>> SetTpoPriceAsync(
        long underwriterId, long vehicleClassId, long periodId, string? carryCapacity,
        decimal? tonnage, decimal price, DateTime? effectiveFrom, long actorId);

    /// <summary>
    /// Shopping-comparison lookup, not scoped to one underwriter - returns
    /// every underwriter currently pricing this vehicle_class+period+
    /// capacity/tonnage combination, cheapest first, via
    /// usp_TpoPriceMapping_GetOptions. Replaces the old single-underwriter
    /// GetTpoPriceAsync, which required the caller to already know which
    /// underwriter to ask - this is the one Agent (and any other
    /// PURCHASE_ON_BEHALF-holding role) actually calls to build a quote.
    /// </summary>
    Task<StoredProcResult<List<TpoPriceOption>>> GetTpoPriceOptionsAsync(
        long vehicleClassId, long periodId, string? carryCapacity, decimal? tonnage);

    Task<StoredProcResult<TpoPriceMappingListPage>> GetTpoPriceListAsync(
        long? underwriterId, long? vehicleClassId, bool? activeOnly, int pageNumber, int pageSize);

    Task<StoredProcResult<long?>> SetComprehensiveRateAsync(
        long underwriterId, long vehicleClassId, decimal baseRatePercent, decimal minPremium,
        DateTime? effectiveFrom, long actorId);

    Task<StoredProcResult<long?>> AddComprehensiveFactorAsync(
        long formulaId, string factorType, decimal factorPercent, long actorId);

    Task<StoredProcResult<List<ComprehensiveRateFactor>>> GetComprehensiveFactorsByFormulaAsync(long formulaId);

    Task<StoredProcResult<ComprehensivePremiumResult?>> CalculateComprehensivePremiumAsync(
        long underwriterId, long vehicleClassId, decimal vehicleValue);

    Task<StoredProcResult<List<ComprehensiveRateBandOption>>> GetComprehensiveRateBandOptionsAsync(decimal vehicleValue);

    Task<StoredProcResult<List<ComprehensiveBenefitItem>>> GetComprehensiveBenefitsAsync(long underwriterId);

    Task<StoredProcResult<List<LiabilityLimitItem>>> GetLiabilityLimitsAsync(long underwriterId);

    Task<StoredProcResult<List<RateBandAdminItem>>> GetRateBandsAllAsync(long? underwriterId);
    Task<StoredProcResult<long?>> UpsertRateBandAsync(long? rateBandId, long underwriterId, decimal minValue, decimal maxValue, decimal ratePercent, decimal minPremium, int displayOrder);
    Task<StoredProcResult> DeleteRateBandAsync(long rateBandId);
    Task<StoredProcResult<List<BenefitAdminItem>>> GetBenefitsAllAsync(long? underwriterId);
    Task<StoredProcResult> UpsertBenefitAsync(long? benefitId, long underwriterId, string benefitCode, string benefitName, decimal defaultPrice, bool isIncludedInBase, string? description, int displayOrder);
    Task<StoredProcResult> DeleteBenefitAsync(long benefitId);
    Task<StoredProcResult<List<LiabilityLimitAdminItem>>> GetLiabilityLimitsAllAsync(long? underwriterId);
    Task<StoredProcResult> UpsertLiabilityLimitAsync(long? liabilityLimitId, long underwriterId, string limitName, string limitValue, int displayOrder);
    Task<StoredProcResult> DeleteLiabilityLimitAsync(long liabilityLimitId);
    Task<StoredProcResult<List<PurchaseTimelineEvent>>> GetPurchaseTimelineAsync(long purchaseId);
}
