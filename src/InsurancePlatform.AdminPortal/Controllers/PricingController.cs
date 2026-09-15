using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

[Authorize(Policy = PermissionCodes.ManagePricing)]
public class PricingController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public PricingController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<IActionResult> Tpo(long? underwriterId, long? vehicleClassId)
    {
        var qs = $"?pageSize=200" +
                 (underwriterId.HasValue ? $"&underwriterId={underwriterId}" : "") +
                 (vehicleClassId.HasValue ? $"&vehicleClassId={vehicleClassId}" : "");

        var mappingsResult = await _apiClient.GetAsync<TpoPriceMappingListPage>($"/api/pricing/tpo/list{qs}");
        var underwritersResult = await _apiClient.GetAsync<List<UnderwriterOption>>("/api/underwriters");
        var classesResult = await _apiClient.GetAsync<List<MotorVehicleClassItem>>("/api/products/motor-vehicle-classes");
        var periodsResult = await _apiClient.GetAsync<List<PeriodItem>>("/api/products/periods");

        var vm = new TpoPriceMappingViewModel
        {
            Mappings = mappingsResult.Success ? mappingsResult.Data ?? new TpoPriceMappingListPage() : new TpoPriceMappingListPage(),
            Underwriters = underwritersResult.Success ? underwritersResult.Data ?? new List<UnderwriterOption>() : new List<UnderwriterOption>(),
            VehicleClasses = classesResult.Success ? classesResult.Data ?? new List<MotorVehicleClassItem>() : new List<MotorVehicleClassItem>(),
            Periods = periodsResult.Success ? periodsResult.Data ?? new List<PeriodItem>() : new List<PeriodItem>(),
            FilterUnderwriterId = underwriterId,
            FilterVehicleClassId = vehicleClassId
        };

        if (!mappingsResult.Success)
        {
            vm.StatusMessage = mappingsResult.Message;
            vm.StatusIsError = true;
        }

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveTpoPrice(SetTpoPriceFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["StatusMessage"] = "Fill in the required fields.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Tpo), new { underwriterId = model.UnderwriterId, vehicleClassId = model.VehicleClassId });
        }

        var result = await _apiClient.PostAsync<object>("/api/pricing/tpo", new
        {
            model.UnderwriterId,
            model.VehicleClassId,
            model.PeriodId,
            model.CarryCapacity,
            model.Tonnage,
            model.Price,
            model.EffectiveFrom
        });

        TempData["StatusMessage"] = result.Success ? "TPO price saved." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Tpo), new { underwriterId = model.UnderwriterId, vehicleClassId = model.VehicleClassId });
    }

    public async Task<IActionResult> Comprehensive(long? underwriterId)
    {
        var bands = await _apiClient.GetAsync<List<RateBandAdminItem>>($"/api/pricing/comprehensive/rate-bands{(underwriterId.HasValue ? $"?underwriterId={underwriterId}" : "")}");
        var benefits = await _apiClient.GetAsync<List<BenefitAdminItem>>($"/api/pricing/comprehensive/benefits{(underwriterId.HasValue ? $"?underwriterId={underwriterId}" : "")}");
        var limits = await _apiClient.GetAsync<List<LiabilityLimitAdminItem>>($"/api/pricing/comprehensive/limits{(underwriterId.HasValue ? $"?underwriterId={underwriterId}" : "")}");

        var underwriters = await _apiClient.GetAsync<List<UnderwriterOption>>("/api/underwriters");

        var vm = new ComprehensiveSettingsViewModel
        {
            FilterUnderwriterId = underwriterId,
            RateBands = bands.Data ?? new(),
            Benefits = benefits.Data ?? new(),
            LiabilityLimits = limits.Data ?? new(),
            Underwriters = underwriters.Data ?? new()
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpsertRateBand(RateBandFormModel model)
    {
        var result = await _apiClient.PostAsync<object>("/api/pricing/comprehensive/rate-bands", model);
        TempData["StatusMessage"] = result.Success ? "Rate band saved." : (result.Message ?? "Failed to save rate band.");
        TempData["StatusIsError"] = !result.Success;
        return RedirectToAction(nameof(Comprehensive), new { underwriterId = model.UnderwriterId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteRateBand(long bandId, long? underwriterId)
    {
        await _apiClient.DeleteAsync<object>($"/api/pricing/comprehensive/rate-bands/{bandId}");
        TempData["StatusMessage"] = "Rate band deleted.";
        return RedirectToAction(nameof(Comprehensive), new { underwriterId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpsertBenefit(BenefitFormModel model)
    {
        var result = await _apiClient.PostAsync<object>("/api/pricing/comprehensive/benefits", model);
        TempData["StatusMessage"] = result.Success ? "Benefit saved." : (result.Message ?? "Failed to save benefit.");
        TempData["StatusIsError"] = !result.Success;
        return RedirectToAction(nameof(Comprehensive), new { underwriterId = model.UnderwriterId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteBenefit(long benefitId, long? underwriterId)
    {
        await _apiClient.DeleteAsync<object>($"/api/pricing/comprehensive/benefits/{benefitId}");
        TempData["StatusMessage"] = "Benefit deleted.";
        return RedirectToAction(nameof(Comprehensive), new { underwriterId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpsertLiabilityLimit(LiabilityLimitFormModel model)
    {
        var result = await _apiClient.PostAsync<object>("/api/pricing/comprehensive/limits", model);
        TempData["StatusMessage"] = result.Success ? "Liability limit saved." : (result.Message ?? "Failed to save liability limit.");
        TempData["StatusIsError"] = !result.Success;
        return RedirectToAction(nameof(Comprehensive), new { underwriterId = model.UnderwriterId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteLiabilityLimit(long limitId, long? underwriterId)
    {
        await _apiClient.DeleteAsync<object>($"/api/pricing/comprehensive/limits/{limitId}");
        TempData["StatusMessage"] = "Liability limit deleted.";
        return RedirectToAction(nameof(Comprehensive), new { underwriterId });
    }
}
