using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Pricing;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Motor pricing - TPO flat pricing and Comprehensive rate formulas.</summary>
// Setting/managing prices (SetTpoPrice, GetTpoPriceList, SetComprehensiveRate,
// AddComprehensiveFactor) requires MANAGE_PRICING (AgentAdmin only).
// GetTpoPriceOptions and CalculateComprehensivePremium are the ones the
// quote/purchase flow actually calls at runtime - these only require
// [Authorize], since any staff role building a purchase needs to price
// one (Agent included - GetTpoPriceOptions is Agent's only path to a
// price now that direct Underwriter browsing is admin-only).
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PricingController : BaseApiController
{
    private readonly IPricingRepository _pricingRepository;
    private readonly ILoggerManager _logger;

    public PricingController(IPricingRepository pricingRepository, ILoggerManager logger, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _pricingRepository = pricingRepository;
        _logger = logger;
    }

    /// <summary>Sets a new active TPO price for one underwriter+vehicle-class+period+capacity combination.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("tpo")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetTpoPrice([FromBody] SetTpoPriceRequest request)
    {
        var result = await _pricingRepository.SetTpoPriceAsync(
            request.UnderwriterId, request.VehicleClassId, request.PeriodId, request.CarryCapacity,
            request.Tonnage, request.Price, request.EffectiveFrom, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"TPO price set failed for underwriter_id={request.UnderwriterId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"TPO price set: tpo_price_id={result.Data}, by user_id={CurrentUserId}.");
        return Success(new { TpoPriceId = result.Data }, result.ResultMessage);
    }

    /// <summary>The Motor "quote" call - every underwriter currently pricing this vehicle class+period+capacity/tonnage combination, cheapest first.</summary>
    // Pass exactly one of carryCapacity/tonnage, matching the vehicle
    // class's RequiresTonnage flag (from GET /api/products/motor-vehicle-classes)
    // - leave the other null. No underwriterId here on purpose - this is
    // the comparison-shopping call (usp_TpoPriceMapping_GetOptions), not a
    // single-underwriter lookup: the caller doesn't know yet which
    // underwriter to buy from, that's the whole point of calling this.
    // Open to any authenticated role (not policy-gated) since this is the
    // one pricing endpoint Agent still needs directly - browsing the
    // Underwriters list or the admin price-management screens (GetTpoPriceList,
    // SetTpoPrice) is what's restricted now, not this.
    /// <response code="200">Always 200 - check Success in the body. An empty list is a valid result (nobody prices this combination yet), not a failure.</response>
    [HttpGet("tpo")]
    [ProducesResponseType(typeof(ApiResponse<List<TpoPriceOption>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTpoPriceOptions(
        [FromQuery] long vehicleClassId, [FromQuery] long periodId,
        [FromQuery] string? carryCapacity, [FromQuery] decimal? tonnage)
    {
        var result = await _pricingRepository.GetTpoPriceOptionsAsync(vehicleClassId, periodId, carryCapacity, tonnage);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_TpoPriceMapping_GetOptions returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Lists TPO prices for the price-management screen - filterable, paginated.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpGet("tpo/list")]
    [ProducesResponseType(typeof(ApiResponse<TpoPriceMappingListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTpoPriceList(
        [FromQuery] long? underwriterId, [FromQuery] long? vehicleClassId, [FromQuery] bool? activeOnly,
        [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _pricingRepository.GetTpoPriceListAsync(underwriterId, vehicleClassId, activeOnly, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_TpoPriceMapping_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Starts a new active Comprehensive rate formula for one underwriter+vehicle-class.</summary>
    // Starts with zero factors - call AddComprehensiveFactor next, against
    // the returned formula_id, for each loading/discount that applies.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("comprehensive/formula")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetComprehensiveRate([FromBody] SetComprehensiveRateRequest request)
    {
        var result = await _pricingRepository.SetComprehensiveRateAsync(
            request.UnderwriterId, request.VehicleClassId, request.BaseRatePercent, request.MinPremium,
            request.EffectiveFrom, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Comprehensive rate set failed for underwriter_id={request.UnderwriterId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Comprehensive rate formula set: formula_id={result.Data}, by user_id={CurrentUserId}.");
        return Success(new { FormulaId = result.Data }, result.ResultMessage);
    }

    /// <summary>Adds one loading/discount factor to an existing formula.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("comprehensive/formula/{formulaId}/factors")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> AddComprehensiveFactor(long formulaId, [FromBody] AddComprehensiveFactorRequest request)
    {
        var result = await _pricingRepository.AddComprehensiveFactorAsync(formulaId, request.FactorType, request.FactorPercent, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Comprehensive rate factor added: factor_id={result.Data}, formula_id={formulaId}, by user_id={CurrentUserId}.");
        return Success(new { FactorId = result.Data }, result.ResultMessage);
    }

    /// <summary>Lists the factors under one formula.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("comprehensive/formula/{formulaId}/factors")]
    [ProducesResponseType(typeof(ApiResponse<List<ComprehensiveRateFactor>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetComprehensiveFactorsByFormula(long formulaId)
    {
        var result = await _pricingRepository.GetComprehensiveFactorsByFormulaAsync(formulaId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_ComprehensiveRateFactor_GetListByFormula returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Calculates a Comprehensive premium - the actual pricing call during a quote/purchase.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("comprehensive/calculate")]
    [ProducesResponseType(typeof(ApiResponse<ComprehensivePremiumResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CalculateComprehensivePremium(
        [FromQuery] long underwriterId, [FromQuery] long vehicleClassId, [FromQuery] decimal vehicleValue)
    {
        var result = await _pricingRepository.CalculateComprehensivePremiumAsync(underwriterId, vehicleClassId, vehicleValue);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Comprehensive comparison - returns all underwriters with their rate, premium, PVT, and optional benefits for a given vehicle value.</summary>
    [HttpGet("comprehensive/compare")]
    [ProducesResponseType(typeof(ApiResponse<ComprehensiveCompareResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetComprehensiveCompare([FromQuery] decimal vehicleValue)
    {
        var bandsResult = await _pricingRepository.GetComprehensiveRateBandOptionsAsync(vehicleValue);

        if (!bandsResult.IsSuccess)
        {
            _logger.LogError($"usp_ComprehensiveRateBand_GetOptions returned ResultCode={bandsResult.ResultCode}: {bandsResult.ResultMessage}");
            return ServerError(bandsResult.ResultMessage);
        }

        var options = bandsResult.Data ?? new List<ComprehensiveRateBandOption>();
        var benefitsByUw = new Dictionary<long, List<ComprehensiveBenefitItem>>();
        var limitsByUw = new Dictionary<long, List<LiabilityLimitItem>>();

        foreach (var opt in options)
        {
            var benResult = await _pricingRepository.GetComprehensiveBenefitsAsync(opt.UnderwriterId);
            if (benResult.IsSuccess && benResult.Data is not null)
            {
                benefitsByUw[opt.UnderwriterId] = benResult.Data;
            }

            var limResult = await _pricingRepository.GetLiabilityLimitsAsync(opt.UnderwriterId);
            if (limResult.IsSuccess && limResult.Data is not null)
            {
                limitsByUw[opt.UnderwriterId] = limResult.Data;
            }
        }

        return Success(new ComprehensiveCompareResult
        {
            Options = options,
            BenefitsByUnderwriter = benefitsByUw,
            LiabilityLimitsByUnderwriter = limitsByUw
        }, bandsResult.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpGet("comprehensive/rate-bands")]
    [ProducesResponseType(typeof(ApiResponse<List<RateBandAdminItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRateBands([FromQuery] long? underwriterId)
    {
        var result = await _pricingRepository.GetRateBandsAllAsync(underwriterId);
        if (!result.IsSuccess) return ServerError(result.ResultMessage);
        return Success(result.Data, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("comprehensive/rate-bands")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpsertRateBand([FromBody] UpsertRateBandRequest request)
    {
        var result = await _pricingRepository.UpsertRateBandAsync(
            request.BandId, request.UnderwriterId, request.ValueMin, request.ValueMax,
            request.RatePercent, request.MinPremium, request.DisplayOrder);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpDelete("comprehensive/rate-bands/{bandId}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteRateBand(long bandId)
    {
        var result = await _pricingRepository.DeleteRateBandAsync(bandId);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpGet("comprehensive/benefits")]
    [ProducesResponseType(typeof(ApiResponse<List<BenefitAdminItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBenefits([FromQuery] long? underwriterId)
    {
        var result = await _pricingRepository.GetBenefitsAllAsync(underwriterId);
        if (!result.IsSuccess) return ServerError(result.ResultMessage);
        return Success(result.Data, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("comprehensive/benefits")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpsertBenefit([FromBody] UpsertBenefitRequest request)
    {
        var result = await _pricingRepository.UpsertBenefitAsync(
            request.BenefitId, request.UnderwriterId, request.BenefitCode, request.BenefitName,
            request.DefaultPrice, request.IsIncludedInBase, request.Description, request.DisplayOrder);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpDelete("comprehensive/benefits/{benefitId}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteBenefit(long benefitId)
    {
        var result = await _pricingRepository.DeleteBenefitAsync(benefitId);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpGet("comprehensive/limits")]
    [ProducesResponseType(typeof(ApiResponse<List<LiabilityLimitAdminItem>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLiabilityLimits([FromQuery] long? underwriterId)
    {
        var result = await _pricingRepository.GetLiabilityLimitsAllAsync(underwriterId);
        if (!result.IsSuccess) return ServerError(result.ResultMessage);
        return Success(result.Data, result.ResultMessage);
    }

    [HttpGet("purchases/{purchaseId}/journey")]
    [ProducesResponseType(typeof(ApiResponse<List<PurchaseTimelineEvent>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPurchaseJourney(long purchaseId)
    {
        var result = await _pricingRepository.GetPurchaseTimelineAsync(purchaseId);
        if (!result.IsSuccess) return ServerError(result.ResultMessage);
        return Success(result.Data, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpPost("comprehensive/limits")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpsertLiabilityLimit([FromBody] UpsertLiabilityLimitRequest request)
    {
        var result = await _pricingRepository.UpsertLiabilityLimitAsync(
            request.LiabilityLimitId, request.UnderwriterId, request.LimitName,
            request.LimitValue, request.DisplayOrder);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }

    [Authorize(Policy = PermissionCodes.ManagePricing)]
    [HttpDelete("comprehensive/limits/{limitId}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteLiabilityLimit(long limitId)
    {
        var result = await _pricingRepository.DeleteLiabilityLimitAsync(limitId);
        if (!result.IsSuccess) return BusinessFailure(result.ResultMessage);
        return Success<object?>(null, result.ResultMessage);
    }
}
