using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The Products catalog - a read-only view of the product hierarchy (the
/// API's products endpoints are all GET-only: products + motor categories +
/// motor vehicle classes + periods + policy levels). No writes happen here,
/// so this screen is deliberately simple; the pricing data it surfaces is
/// edited on the Pricing screen instead. Gated to QuoteBackoffice (SA/AA/SP)
/// mirroring GET /api/products's [Authorize]-only stance but kept narrow to
/// the staff roles that actually price policies.
/// </summary>
[Authorize(Roles = RoleCodes.QuoteBackoffice)]
public class ProductsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public ProductsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var products = await _apiClient.GetAsync<List<ProductItem>>("/api/products");
        var categories = await _apiClient.GetAsync<List<MotorCategoryItem>>("/api/products/motor-categories");
        var classes = await _apiClient.GetAsync<List<MotorVehicleClassItem>>("/api/products/motor-vehicle-classes");
        var periods = await _apiClient.GetAsync<List<PeriodItem>>("/api/products/periods");
        var levels = await _apiClient.GetAsync<List<PolicyLevelOption>>("/api/products/policy-levels");

        var vm = new ProductsIndexViewModel
        {
            Products = products.Success ? products.Data ?? new List<ProductItem>() : new List<ProductItem>(),
            MotorCategories = categories.Success ? categories.Data ?? new List<MotorCategoryItem>() : new List<MotorCategoryItem>(),
            VehicleClasses = classes.Success ? classes.Data ?? new List<MotorVehicleClassItem>() : new List<MotorVehicleClassItem>(),
            Periods = periods.Success ? periods.Data ?? new List<PeriodItem>() : new List<PeriodItem>(),
            PolicyLevels = levels.Success ? levels.Data ?? new List<PolicyLevelOption>() : new List<PolicyLevelOption>()
        };

        return View(vm);
    }
}