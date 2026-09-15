using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>
/// Read-only catalog endpoints. No authentication required - the product
/// list is public information (needed before a client has even logged in,
/// e.g. to show pricing on the public website).
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ProductsController : BaseApiController
{
    private readonly IProductRepository _productRepository;
    private readonly ILoggerManager _logger;

    public ProductsController(IProductRepository productRepository, ILoggerManager logger, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _productRepository = productRepository;
        _logger = logger;
    }

    /// <summary>
    /// Returns every active insurance product (Motor Comprehensive, Motor TPO,
    /// Medical Individual, Medical Corporate, Professional Indemnity, Travel,
    /// Domestic). Takes no parameters.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<Product>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList()
    {
        _logger.LogInfo("GET /api/products - fetching active product list.");

        var result = await _productRepository.GetListAsync();

        if (!result.IsSuccess)
        {
            // A failed usp_Product_GetList call isn't something the caller
            // did wrong - it's a real server-side problem, hence 500 via
            // ServerError rather than 200 via BusinessFailure.
            _logger.LogError($"usp_Product_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        _logger.LogInfo($"GET /api/products - returned {result.Data?.Count ?? 0} products.");
        return Success(result.Data, "Products retrieved.");
    }

    /// <summary>Returns every Motor category.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("motor-categories")]
    [ProducesResponseType(typeof(ApiResponse<List<MotorCategory>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMotorCategories()
    {
        var result = await _productRepository.GetMotorCategoriesAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_MotorCategory_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, "Motor categories retrieved.");
    }

    /// <summary>Returns every Motor vehicle class.</summary>
    // RequiresTonnage on each row tells the caller whether that class prices
    // by tonnage (Commercial) or carry_capacity (PSV) when calling the TPO
    // pricing lookup.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("motor-vehicle-classes")]
    [ProducesResponseType(typeof(ApiResponse<List<MotorVehicleClass>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMotorVehicleClasses()
    {
        var result = await _productRepository.GetMotorVehicleClassesAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_MotorVehicleClass_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, "Motor vehicle classes retrieved.");
    }

    /// <summary>Returns every active cover period (e.g. Annual, Monthly).</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("periods")]
    [ProducesResponseType(typeof(ApiResponse<List<Period>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPeriods()
    {
        var result = await _productRepository.GetPeriodsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Period_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, "Periods retrieved.");
    }

    /// <summary>Returns every motor policy level (e.g. "Type C - Private Car") - what MotorVehicleClasses.policyLevelId and the Underwriter fixed-policy-number endpoints reference.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("policy-levels")]
    [ProducesResponseType(typeof(ApiResponse<List<PolicyLevel>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPolicyLevels()
    {
        var result = await _productRepository.GetPolicyLevelsAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_PolicyLevel_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, "Policy levels retrieved.");
    }
}
