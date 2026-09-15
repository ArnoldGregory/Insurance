using System.Text.Json;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

[Authorize(Roles = RoleCodes.PurchaseCreators)]
public class PurchaseWizardController : Controller
{
    private const string DraftKey = "PurchaseWizardDraft";
    private const string CompDraftKey = "ComprehensiveDraft";

    private readonly IInsuranceApiClient _apiClient;

    public PurchaseWizardController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    // ==================== COMPREHENSIVE WIZARD ====================

    [HttpGet]
    public async Task<IActionResult> Comprehensive(bool reset = false)
    {
        var draft = new ComprehensiveWizardDraft();
        SaveCompDraft(draft);

        var vm = new ComprehensiveStep1ViewModel
        {
            VehicleValue = draft.VehicleValue,
            CompareOptions = draft.CompareOptions,
            BenefitsByUnderwriter = draft.BenefitsByUnderwriter,
            SelectedUnderwriterId = draft.SelectedUnderwriterId,
            SelectedUnderwriterName = draft.SelectedUnderwriterName,
            SelectedTotalPremium = draft.SelectedTotalPremium
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ComprehensiveStep1Generate(ComprehensiveStep1ViewModel model)
    {
        if (model.VehicleValue is null || model.VehicleValue <= 0)
        {
            model.ErrorMessage = "Enter a vehicle value.";
            return View("Comprehensive", model);
        }

        var compareResult = await _apiClient.GetAsync<ComprehensiveCompareResult>(
            $"/api/pricing/comprehensive/compare?vehicleValue={model.VehicleValue}");

        if (!compareResult.Success || compareResult.Data is null)
        {
            model.ErrorMessage = compareResult.Message ?? "Could not load underwriter pricing.";
            return View("Comprehensive", model);
        }

        model.CompareOptions = compareResult.Data.Options;
        model.BenefitsByUnderwriter = compareResult.Data.BenefitsByUnderwriter;
        model.LiabilityLimitsByUnderwriter = compareResult.Data.LiabilityLimitsByUnderwriter;

        if (model.CompareOptions.Count == 0)
        {
            model.ErrorMessage = "No underwriter currently prices this vehicle value - try a different amount.";
        }

        var draft = LoadCompDraft();
        draft.VehicleValue = model.VehicleValue;
        draft.CompareOptions = model.CompareOptions;
        draft.BenefitsByUnderwriter = model.BenefitsByUnderwriter;
        draft.LiabilityLimitsByUnderwriter = model.LiabilityLimitsByUnderwriter;
        draft.SelectedUnderwriterId = null;
        draft.SelectedUnderwriterName = null;
        draft.SelectedBasePremium = null;
        draft.SelectedTotalPremium = null;
        draft.SelectedBenefitCodes = null;
        SaveCompDraft(draft);

        return View("Comprehensive", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ComprehensiveStep1Next(long selectedUnderwriterId, string selectedUnderwriterName, decimal totalPremium, decimal basePremium, string? benefitCodes)
    {
        var draft = LoadCompDraft();

        if (draft.VehicleValue is null || draft.CompareOptions is null)
        {
            TempData["StatusMessage"] = "Generate a quote first.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Comprehensive));
        }

        draft.SelectedUnderwriterId = selectedUnderwriterId;
        draft.SelectedUnderwriterName = selectedUnderwriterName;
        draft.SelectedBasePremium = basePremium;
        draft.SelectedTotalPremium = totalPremium;
        draft.SelectedBenefitCodes = benefitCodes;
        SaveCompDraft(draft);

        return RedirectToAction(nameof(ComprehensiveStep2));
    }

    // ==================== COMPREHENSIVE STEP 2 ====================

    [HttpGet]
    public async Task<IActionResult> ComprehensiveStep2()
    {
        var draft = LoadCompDraft();

        if (!draft.HasSelection)
        {
            TempData["StatusMessage"] = "Select an underwriter first.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Comprehensive));
        }

        var vm = new ComprehensiveStep2ViewModel
        {
            VehicleValue = draft.VehicleValue,
            SelectedUnderwriterName = draft.SelectedUnderwriterName,
            SelectedTotalPremium = draft.SelectedTotalPremium,
            SelectedBenefitCodes = draft.SelectedBenefitCodes,
            VehicleClasses = await GetVehicleClassesAsync(),
            Periods = await GetPeriodsAsync(),
            VehicleClassId = draft.VehicleClassId,
            PeriodId = draft.PeriodId,
            ClientIdNo = draft.ClientIdNo ?? string.Empty,
            ClientFullName = draft.ClientFullName ?? string.Empty,
            ClientDob = draft.ClientDob,
            ClientEmail = draft.ClientEmail,
            ClientPhone = draft.ClientPhone ?? string.Empty,
            ClientAddress = draft.ClientAddress,
            ClientKraPin = draft.ClientKraPin,
            VehicleRegNo = draft.VehicleRegNo ?? string.Empty,
            VehicleMake = draft.VehicleMake,
            VehicleModel = draft.VehicleModel,
            VehicleChassisNo = draft.VehicleChassisNo,
            VehicleEngineNo = draft.VehicleEngineNo,
            VehicleYearOfManufacture = draft.VehicleYearOfManufacture,
            VehicleBodyType = draft.VehicleBodyType,
            VehicleFuelType = draft.VehicleFuelType,
            LicensedToCarry = draft.LicensedToCarry,
            AntiTheft = draft.AntiTheft,
            Risk = draft.Risk,
            StartDate = draft.StartDate ?? DateTime.Today
        };

        SaveCompDraft(draft);
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ComprehensiveStep2Next(ComprehensiveStep2ViewModel model)
    {
        var draft = LoadCompDraft();

        if (!draft.HasSelection)
        {
            TempData["StatusMessage"] = "Select an underwriter first.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Comprehensive));
        }

        model.VehicleValue = draft.VehicleValue;
        model.SelectedUnderwriterName = draft.SelectedUnderwriterName;
        model.SelectedTotalPremium = draft.SelectedTotalPremium;
        model.SelectedBenefitCodes = draft.SelectedBenefitCodes;
        model.VehicleClasses = await GetVehicleClassesAsync();
        model.Periods = await GetPeriodsAsync();

        if (!ModelState.IsValid)
        {
            return View("ComprehensiveStep2", model);
        }

        draft.VehicleClassId = model.VehicleClassId;
        draft.VehicleClassName = model.VehicleClasses.FirstOrDefault(c => c.VehicleClassId == model.VehicleClassId)?.Name;
        draft.PeriodId = model.PeriodId;
        draft.PeriodName = model.Periods.FirstOrDefault(p => p.PeriodId == model.PeriodId)?.Name;
        draft.ClientIdNo = model.ClientIdNo;
        draft.ClientFullName = model.ClientFullName;
        draft.ClientDob = model.ClientDob;
        draft.ClientEmail = model.ClientEmail;
        draft.ClientPhone = model.ClientPhone;
        draft.ClientAddress = model.ClientAddress;
        draft.ClientKraPin = model.ClientKraPin;
        draft.VehicleRegNo = model.VehicleRegNo;
        draft.VehicleMake = model.VehicleMake;
        draft.VehicleModel = model.VehicleModel;
        draft.VehicleChassisNo = model.VehicleChassisNo;
        draft.VehicleEngineNo = model.VehicleEngineNo;
        draft.VehicleYearOfManufacture = model.VehicleYearOfManufacture;
        draft.VehicleBodyType = model.VehicleBodyType;
        draft.VehicleFuelType = model.VehicleFuelType;
        draft.LicensedToCarry = model.LicensedToCarry;
        draft.AntiTheft = model.AntiTheft;
        draft.Risk = model.Risk;
        draft.StartDate = model.StartDate;
        SaveCompDraft(draft);

        if (draft.ClientId is null)
        {
            var lookup = await _apiClient.GetAsync<ClientLookupResult>($"/api/clients/resolve/{Uri.EscapeDataString(model.ClientIdNo)}");

            if (lookup.Success && lookup.Data is not null && lookup.Data.MatchStatus != "NOT_FOUND" && lookup.Data.ClientId is not null)
            {
                draft.ClientId = lookup.Data.ClientId;
            }
            else
            {
                var createClient = await _apiClient.PostAsync<ClientIdResult>("/api/clients", new
                {
                    IdNo = model.ClientIdNo,
                    FullName = model.ClientFullName,
                    Dob = model.ClientDob,
                    Email = model.ClientEmail,
                    Phone = model.ClientPhone,
                    Address = model.ClientAddress,
                    KraPin = model.ClientKraPin,
                    RegistrationChannel = "PORTAL"
                });

                if (!createClient.Success || createClient.Data is null)
                {
                    model.ErrorMessage = $"Could not save the client: {createClient.Message}";
                    SaveCompDraft(draft);
                    return View("ComprehensiveStep2", model);
                }

                draft.ClientId = createClient.Data.ClientId;
            }

            SaveCompDraft(draft);
        }

        if (draft.VehicleId is null)
        {
            var vehicleLookup = await _apiClient.GetAsync<VehicleIdResult>($"/api/vehicles/by-reg-no/{Uri.EscapeDataString(model.VehicleRegNo)}");

            if (vehicleLookup.Success && vehicleLookup.Data is not null)
            {
                draft.VehicleId = vehicleLookup.Data.VehicleId;
            }
            else
            {
                var createVehicle = await _apiClient.PostAsync<VehicleIdResult>($"/api/clients/{draft.ClientId}/vehicles", new
                {
                    Make = model.VehicleMake,
                    Model = model.VehicleModel,
                    RegNo = model.VehicleRegNo,
                    ChassisNo = model.VehicleChassisNo,
                    EngineNo = model.VehicleEngineNo,
                    YearOfManufacture = model.VehicleYearOfManufacture,
                    VehicleType = draft.VehicleClassName,
                    BodyType = model.VehicleBodyType,
                    FuelType = model.VehicleFuelType,
                    CubicCapacity = (string?)null,
                    Color = (string?)null,
                    Logbook = (string?)null
                });

                if (!createVehicle.Success || createVehicle.Data is null)
                {
                    model.ErrorMessage = $"Client saved (ID #{draft.ClientId}), but the vehicle could not be saved: {createVehicle.Message}";
                    SaveCompDraft(draft);
                    return View("ComprehensiveStep2", model);
                }

                draft.VehicleId = createVehicle.Data.VehicleId;
            }

            SaveCompDraft(draft);
        }

        var productsResult = await _apiClient.GetAsync<List<ProductOption>>("/api/products");
        var motorProduct = productsResult.Success ? productsResult.Data?.FirstOrDefault(p => p.Code == "MOTOR") : null;

        if (motorProduct is null)
        {
            model.ErrorMessage = "Could not resolve the \"Motor\" product - contact a SuperAdmin.";
            return View("ComprehensiveStep2", model);
        }

        var purchaseResult = await _apiClient.PostAsync<PurchaseCreateResultData>("/api/purchases", new
        {
            ProductId = motorProduct.ProductId,
            ClientId = draft.ClientId!.Value,
            UnderwriterId = draft.SelectedUnderwriterId!.Value,
            QuoteOfferId = (long?)null,
            PremiumAmount = draft.SelectedTotalPremium!.Value,
            PeriodId = draft.PeriodId!.Value,
            StartDate = model.StartDate,
            PolicyNumber = (string?)null,
            VehicleId = draft.VehicleId!.Value,
            VehicleValue = draft.VehicleValue,
            Tonnage = (decimal?)null,
            LicensedToCarry = model.LicensedToCarry,
            AntiTheft = model.AntiTheft,
            Risk = model.Risk,
            SnapshotAmount = (decimal?)null
        });

        if (!purchaseResult.Success || purchaseResult.Data is null)
        {
            model.ErrorMessage = $"Client and vehicle saved, but the purchase could not be created: {purchaseResult.Message}";
            return View("ComprehensiveStep2", model);
        }

        draft.PurchaseId = purchaseResult.Data.PurchaseId;
        draft.PolicyNumber = purchaseResult.Data.PolicyNumber;
        draft.EndDate = purchaseResult.Data.EndDate;
        draft.AccountNumber = purchaseResult.Data.AccountNumber;
        draft.PaybillNumber = purchaseResult.Data.PaybillNumber;
        SaveCompDraft(draft);

        return RedirectToAction(nameof(ComprehensiveStep3));
    }

    // ==================== COMPREHENSIVE STEP 3 - PAYMENT ====================

    [HttpGet]
    public async Task<IActionResult> ComprehensiveStep3()
    {
        var draft = LoadCompDraft();

        if (!draft.HasPurchase)
        {
            TempData["StatusMessage"] = "Complete client and vehicle details first.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(ComprehensiveStep2));
        }

        var paymentsResult = await _apiClient.GetAsync<List<PaymentItem>>($"/api/payments/by-purchase/{draft.PurchaseId}");
        var attempts = paymentsResult.Success ? paymentsResult.Data ?? new List<PaymentItem>() : new List<PaymentItem>();

        var vm = new WizardStep3ViewModel
        {
            PurchaseId = draft.PurchaseId!.Value,
            PolicyNumber = draft.PolicyNumber,
            EndDate = draft.EndDate,
            AccountNumber = draft.AccountNumber ?? string.Empty,
            PaybillNumber = draft.PaybillNumber ?? string.Empty,
            PremiumAmount = draft.SelectedTotalPremium ?? 0,
            PaymentAttempts = attempts,
            IsPaid = attempts.Any(p => p.Status == "SUCCESS"),
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        SaveCompDraft(draft);
        return View("ComprehensiveStep3", vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ComprehensiveStep3InitiateStk(string mpesaPhoneNumber)
    {
        var draft = LoadCompDraft();

        if (!draft.HasPurchase)
            return RedirectToAction(nameof(Comprehensive));

        if (string.IsNullOrWhiteSpace(mpesaPhoneNumber))
        {
            TempData["StatusMessage"] = "Enter an M-Pesa phone number.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(ComprehensiveStep3));
        }

        var result = await _apiClient.PostAsync<StkPushResultData>("/api/payments/stk-push", new
        {
            PurchaseId = draft.PurchaseId!.Value,
            Amount = draft.SelectedTotalPremium!.Value,
            PhoneNumber = mpesaPhoneNumber,
            AccountReference = draft.AccountNumber
        });

        TempData["StatusMessage"] = result.Message;
        TempData["StatusIsError"] = !result.Success || (result.Data is not null && !result.Data.PushSent);

        return RedirectToAction(nameof(ComprehensiveStep3));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ComprehensiveStep3Next()
    {
        var draft = LoadCompDraft();

        if (!draft.HasPurchase)
            return RedirectToAction(nameof(Comprehensive));

        var paymentsResult = await _apiClient.GetAsync<List<PaymentItem>>($"/api/payments/by-purchase/{draft.PurchaseId}");
        var attempts = paymentsResult.Success ? paymentsResult.Data ?? new List<PaymentItem>() : new List<PaymentItem>();

        if (!attempts.Any(p => p.Status == "SUCCESS"))
        {
            TempData["StatusMessage"] = "This purchase hasn't been confirmed as paid yet - initiate an STK push, or wait for the customer to pay via Paybill and try again.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(ComprehensiveStep3));
        }

        SaveCompDraft(draft);
        return RedirectToAction(nameof(ComprehensiveStep4));
    }

    // ==================== COMPREHENSIVE STEP 4 - SUMMARY ====================

    [HttpGet]
    public async Task<IActionResult> ComprehensiveStep4()
    {
        var draft = LoadCompDraft();

        if (!draft.HasPurchase)
            return RedirectToAction(nameof(Comprehensive));

        var purchaseResult = await _apiClient.GetAsync<PurchaseDetail>($"/api/purchases/{draft.PurchaseId}");

        if (!purchaseResult.Success || purchaseResult.Data is null)
        {
            TempData["StatusMessage"] = purchaseResult.Message;
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(ComprehensiveStep3));
        }

        var vm = new WizardStep4ViewModel
        {
            Purchase = purchaseResult.Data,
            ClientName = draft.ClientFullName ?? string.Empty
        };

        return View("ComprehensiveStep4", vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ComprehensiveFinish()
    {
        TempData.Remove(CompDraftKey);
        TempData["StatusMessage"] = "Comprehensive purchase completed.";
        return RedirectToAction("Index", "Purchases");
    }

    // ==================== TPO WIZARD ====================

    [HttpGet]
    public async Task<IActionResult> Step1(bool reset = false)
    {
        var draft = reset ? new PurchaseWizardDraft() : LoadDraft();
        SaveDraft(draft);

        var vm = new WizardStep1ViewModel
        {
            VehicleClasses = await GetVehicleClassesAsync(),
            Periods = await GetPeriodsAsync(),
            VehicleClassId = draft.VehicleClassId,
            PeriodId = draft.PeriodId,
            CarryCapacity = draft.CarryCapacity,
            Tonnage = draft.Tonnage,
            QuoteOptions = draft.QuoteOptions,
            SelectedTpoPriceId = draft.SelectedTpoPriceId
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Step1Generate(WizardStep1ViewModel model)
    {
        model.VehicleClasses = await GetVehicleClassesAsync();
        model.Periods = await GetPeriodsAsync();

        if (model.VehicleClassId is null || model.PeriodId is null)
        {
            model.ErrorMessage = "Pick a vehicle class and a period first.";
            return View("Step1", model);
        }

        var selectedClass = model.VehicleClasses.FirstOrDefault(c => c.VehicleClassId == model.VehicleClassId);
        if (selectedClass is null) { model.ErrorMessage = "Unrecognized vehicle class."; return View("Step1", model); }
        if (selectedClass.RequiresTonnage && model.Tonnage is null) { model.ErrorMessage = $"\"{selectedClass.Name}\" prices by tonnage - enter a tonnage value."; return View("Step1", model); }
        if (!selectedClass.RequiresTonnage && string.IsNullOrWhiteSpace(model.CarryCapacity)) { model.ErrorMessage = $"\"{selectedClass.Name}\" prices by carry capacity - enter a value."; return View("Step1", model); }

        var query = $"/api/pricing/tpo?vehicleClassId={model.VehicleClassId}&periodId={model.PeriodId}";
        query += selectedClass.RequiresTonnage ? $"&tonnage={model.Tonnage}" : $"&carryCapacity={Uri.EscapeDataString(model.CarryCapacity!)}";

        var quoteResult = await _apiClient.GetAsync<List<TpoQuoteOption>>(query);
        if (!quoteResult.Success) { model.ErrorMessage = quoteResult.Message; return View("Step1", model); }

        model.QuoteOptions = quoteResult.Data ?? new List<TpoQuoteOption>();
        if (model.QuoteOptions.Count == 0) model.ErrorMessage = "No underwriter currently prices this combination - try a different vehicle class, period, or tonnage/capacity.";

        var draft = LoadDraft();
        draft.VehicleClassId = model.VehicleClassId; draft.VehicleClassName = selectedClass.Name; draft.RequiresTonnage = selectedClass.RequiresTonnage;
        draft.PeriodId = model.PeriodId; draft.PeriodName = model.Periods.FirstOrDefault(p => p.PeriodId == model.PeriodId)?.Name;
        draft.CarryCapacity = model.CarryCapacity; draft.Tonnage = model.Tonnage;
        draft.SelectedTpoPriceId = null; draft.SelectedUnderwriterId = null; draft.SelectedUnderwriterName = null; draft.SelectedPremium = null;
        draft.QuoteOptions = model.QuoteOptions;
        SaveDraft(draft);
        return View("Step1", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Step1Next(long selectedTpoPriceId, long selectedUnderwriterId, string selectedUnderwriterName, decimal selectedPremium)
    {
        var draft = LoadDraft();
        if (draft.VehicleClassId is null || draft.PeriodId is null) { TempData["StatusMessage"] = "Generate a quote first."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step1)); }
        draft.SelectedTpoPriceId = selectedTpoPriceId; draft.SelectedUnderwriterId = selectedUnderwriterId; draft.SelectedUnderwriterName = selectedUnderwriterName; draft.SelectedPremium = selectedPremium;
        SaveDraft(draft);
        return RedirectToAction(nameof(Step2));
    }

    // ==================== TPO STEP 2 - CLIENT + VEHICLE ====================

    [HttpGet]
    public IActionResult Step2()
    {
        var draft = LoadDraft();
        if (!draft.HasQuoteSelection) { TempData["StatusMessage"] = "Generate and select a quote first."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step1)); }
        var vm = new WizardStep2ViewModel { VehicleClassName = draft.VehicleClassName, PeriodName = draft.PeriodName, SelectedUnderwriterName = draft.SelectedUnderwriterName, SelectedPremium = draft.SelectedPremium, ClientIdNo = draft.ClientIdNo ?? string.Empty, ClientFullName = draft.ClientFullName ?? string.Empty, ClientDob = draft.ClientDob, ClientEmail = draft.ClientEmail, ClientPhone = draft.ClientPhone ?? string.Empty, ClientAddress = draft.ClientAddress, ClientKraPin = draft.ClientKraPin, VehicleRegNo = draft.VehicleRegNo ?? string.Empty, VehicleMake = draft.VehicleMake, VehicleModel = draft.VehicleModel, VehicleChassisNo = draft.VehicleChassisNo, VehicleEngineNo = draft.VehicleEngineNo, VehicleYearOfManufacture = draft.VehicleYearOfManufacture, VehicleBodyType = draft.VehicleBodyType, VehicleFuelType = draft.VehicleFuelType, VehicleValue = draft.VehicleValue, LicensedToCarry = draft.LicensedToCarry, AntiTheft = draft.AntiTheft, Risk = draft.Risk, StartDate = draft.StartDate ?? DateTime.Today };
        SaveDraft(draft);
        return View(vm);
    }

    [HttpGet]
    public async Task<IActionResult> LookupClient(string idNo)
    {
        if (string.IsNullOrWhiteSpace(idNo)) return Json(new { found = false });
        var result = await _apiClient.GetAsync<ClientLookupResult>($"/api/clients/resolve/{Uri.EscapeDataString(idNo)}");
        if (!result.Success || result.Data is null || result.Data.MatchStatus == "NOT_FOUND" || result.Data.ClientId is null) return Json(new { found = false });
        var c = result.Data;
        return Json(new { found = true, clientId = c.ClientId, fullName = c.FullName, phone = c.Phone, email = c.Email, kraPin = c.KraPin });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Step2Next(WizardStep2ViewModel model)
    {
        var draft = LoadDraft();
        if (!draft.HasQuoteSelection) { TempData["StatusMessage"] = "Generate and select a quote first."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step1)); }
        model.VehicleClassName = draft.VehicleClassName; model.PeriodName = draft.PeriodName; model.SelectedUnderwriterName = draft.SelectedUnderwriterName; model.SelectedPremium = draft.SelectedPremium;
        if (!ModelState.IsValid) return View("Step2", model);

        draft.ClientIdNo = model.ClientIdNo; draft.ClientFullName = model.ClientFullName; draft.ClientDob = model.ClientDob; draft.ClientEmail = model.ClientEmail; draft.ClientPhone = model.ClientPhone; draft.ClientAddress = model.ClientAddress; draft.ClientKraPin = model.ClientKraPin;
        draft.VehicleRegNo = model.VehicleRegNo; draft.VehicleMake = model.VehicleMake; draft.VehicleModel = model.VehicleModel; draft.VehicleChassisNo = model.VehicleChassisNo; draft.VehicleEngineNo = model.VehicleEngineNo; draft.VehicleYearOfManufacture = model.VehicleYearOfManufacture; draft.VehicleBodyType = model.VehicleBodyType; draft.VehicleFuelType = model.VehicleFuelType; draft.VehicleValue = model.VehicleValue; draft.LicensedToCarry = model.LicensedToCarry; draft.AntiTheft = model.AntiTheft; draft.Risk = model.Risk; draft.StartDate = model.StartDate;
        SaveDraft(draft);

        if (draft.ClientId is null)
        {
            var lookup = await _apiClient.GetAsync<ClientLookupResult>($"/api/clients/resolve/{Uri.EscapeDataString(model.ClientIdNo)}");
            if (lookup.Success && lookup.Data is not null && lookup.Data.MatchStatus != "NOT_FOUND" && lookup.Data.ClientId is not null) { draft.ClientId = lookup.Data.ClientId; }
            else { var createClient = await _apiClient.PostAsync<ClientIdResult>("/api/clients", new { IdNo = model.ClientIdNo, FullName = model.ClientFullName, Dob = model.ClientDob, Email = model.ClientEmail, Phone = model.ClientPhone, Address = model.ClientAddress, KraPin = model.ClientKraPin, RegistrationChannel = "PORTAL" }); if (!createClient.Success || createClient.Data is null) { model.ErrorMessage = $"Could not save the client: {createClient.Message}"; SaveDraft(draft); return View("Step2", model); } draft.ClientId = createClient.Data.ClientId; }
            SaveDraft(draft);
        }
        if (draft.VehicleId is null)
        {
            var vehicleLookup = await _apiClient.GetAsync<VehicleIdResult>($"/api/vehicles/by-reg-no/{Uri.EscapeDataString(model.VehicleRegNo)}");
            if (vehicleLookup.Success && vehicleLookup.Data is not null) { draft.VehicleId = vehicleLookup.Data.VehicleId; }
            else { var createVehicle = await _apiClient.PostAsync<VehicleIdResult>($"/api/clients/{draft.ClientId}/vehicles", new { Make = model.VehicleMake, Model = model.VehicleModel, RegNo = model.VehicleRegNo, ChassisNo = model.VehicleChassisNo, EngineNo = model.VehicleEngineNo, YearOfManufacture = model.VehicleYearOfManufacture, VehicleType = draft.VehicleClassName, BodyType = model.VehicleBodyType, FuelType = model.VehicleFuelType, CubicCapacity = (string?)null, Color = (string?)null, Logbook = (string?)null }); if (!createVehicle.Success || createVehicle.Data is null) { model.ErrorMessage = $"Client saved (ID #{draft.ClientId}), but the vehicle could not be saved: {createVehicle.Message}"; SaveDraft(draft); return View("Step2", model); } draft.VehicleId = createVehicle.Data.VehicleId; }
            SaveDraft(draft);
        }

        var productsResult = await _apiClient.GetAsync<List<ProductOption>>("/api/products");
        var motorProduct = productsResult.Success ? productsResult.Data?.FirstOrDefault(p => p.Code == "MOTOR") : null;
        if (motorProduct is null) { model.ErrorMessage = "Could not resolve the \"Motor\" product - contact a SuperAdmin."; return View("Step2", model); }

        var purchaseResult = await _apiClient.PostAsync<PurchaseCreateResultData>("/api/purchases", new { ProductId = motorProduct.ProductId, ClientId = draft.ClientId!.Value, UnderwriterId = draft.SelectedUnderwriterId!.Value, QuoteOfferId = (long?)null, PremiumAmount = draft.SelectedPremium!.Value, PeriodId = draft.PeriodId!.Value, StartDate = model.StartDate, PolicyNumber = (string?)null, VehicleId = draft.VehicleId!.Value, VehicleValue = model.VehicleValue, Tonnage = draft.Tonnage, LicensedToCarry = model.LicensedToCarry, AntiTheft = model.AntiTheft, Risk = model.Risk, SnapshotAmount = (decimal?)null });
        if (!purchaseResult.Success || purchaseResult.Data is null) { model.ErrorMessage = $"Client and vehicle saved, but the purchase could not be created: {purchaseResult.Message}"; return View("Step2", model); }

        draft.PurchaseId = purchaseResult.Data.PurchaseId; draft.PolicyNumber = purchaseResult.Data.PolicyNumber; draft.EndDate = purchaseResult.Data.EndDate; draft.AccountNumber = purchaseResult.Data.AccountNumber; draft.PaybillNumber = purchaseResult.Data.PaybillNumber;
        SaveDraft(draft);
        return RedirectToAction(nameof(Step3));
    }

    // ==================== TPO STEP 3 - PAYMENT ====================

    [HttpGet]
    public async Task<IActionResult> Step3()
    {
        var draft = LoadDraft();
        if (!draft.HasPurchase) { TempData["StatusMessage"] = "Complete client and vehicle details first."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step2)); }
        var paymentsResult = await _apiClient.GetAsync<List<PaymentItem>>($"/api/payments/by-purchase/{draft.PurchaseId}");
        var attempts = paymentsResult.Success ? paymentsResult.Data ?? new List<PaymentItem>() : new List<PaymentItem>();
        var vm = new WizardStep3ViewModel { PurchaseId = draft.PurchaseId!.Value, PolicyNumber = draft.PolicyNumber, EndDate = draft.EndDate, AccountNumber = draft.AccountNumber ?? string.Empty, PaybillNumber = draft.PaybillNumber ?? string.Empty, PremiumAmount = draft.SelectedPremium ?? 0, PaymentAttempts = attempts, IsPaid = attempts.Any(p => p.Status == "SUCCESS"), StatusMessage = TempData["StatusMessage"] as string, StatusIsError = TempData["StatusIsError"] is true };
        SaveDraft(draft);
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Step3InitiateStk(string mpesaPhoneNumber)
    {
        var draft = LoadDraft();
        if (!draft.HasPurchase) return RedirectToAction(nameof(Step1));
        if (string.IsNullOrWhiteSpace(mpesaPhoneNumber)) { TempData["StatusMessage"] = "Enter an M-Pesa phone number."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step3)); }
        var result = await _apiClient.PostAsync<StkPushResultData>("/api/payments/stk-push", new { PurchaseId = draft.PurchaseId!.Value, Amount = draft.SelectedPremium!.Value, PhoneNumber = mpesaPhoneNumber, AccountReference = draft.AccountNumber });
        TempData["StatusMessage"] = result.Message; TempData["StatusIsError"] = !result.Success || (result.Data is not null && !result.Data.PushSent);
        return RedirectToAction(nameof(Step3));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Step3Next()
    {
        var draft = LoadDraft();
        if (!draft.HasPurchase) return RedirectToAction(nameof(Step1));
        var paymentsResult = await _apiClient.GetAsync<List<PaymentItem>>($"/api/payments/by-purchase/{draft.PurchaseId}");
        var attempts = paymentsResult.Success ? paymentsResult.Data ?? new List<PaymentItem>() : new List<PaymentItem>();
        if (!attempts.Any(p => p.Status == "SUCCESS")) { TempData["StatusMessage"] = "This purchase hasn't been confirmed as paid yet - initiate an STK push, or wait for the customer to pay via Paybill and try again."; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step3)); }
        SaveDraft(draft);
        return RedirectToAction(nameof(Step4));
    }

    // ==================== TPO STEP 4 - SUMMARY ====================

    [HttpGet]
    public async Task<IActionResult> Step4()
    {
        var draft = LoadDraft();
        if (!draft.HasPurchase) return RedirectToAction(nameof(Step1));
        var purchaseResult = await _apiClient.GetAsync<PurchaseDetail>($"/api/purchases/{draft.PurchaseId}");
        if (!purchaseResult.Success || purchaseResult.Data is null) { TempData["StatusMessage"] = purchaseResult.Message; TempData["StatusIsError"] = true; return RedirectToAction(nameof(Step3)); }
        var vm = new WizardStep4ViewModel { Purchase = purchaseResult.Data, ClientName = draft.ClientFullName ?? string.Empty };
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Finish()
    {
        TempData.Remove(DraftKey);
        TempData["StatusMessage"] = "Purchase completed.";
        return RedirectToAction("Index", "Purchases");
    }

    // ==================== HELPERS ====================

    private PurchaseWizardDraft LoadDraft()
    {
        var json = TempData[DraftKey] as string;
        TempData.Keep(DraftKey);
        return string.IsNullOrEmpty(json) ? new PurchaseWizardDraft() : (JsonSerializer.Deserialize<PurchaseWizardDraft>(json) ?? new PurchaseWizardDraft());
    }

    private void SaveDraft(PurchaseWizardDraft draft) => TempData[DraftKey] = JsonSerializer.Serialize(draft);

    private ComprehensiveWizardDraft LoadCompDraft()
    {
        var json = HttpContext.Session.GetString(CompDraftKey);
        return string.IsNullOrEmpty(json) ? new ComprehensiveWizardDraft() : (JsonSerializer.Deserialize<ComprehensiveWizardDraft>(json) ?? new ComprehensiveWizardDraft());
    }

    private void SaveCompDraft(ComprehensiveWizardDraft draft) => HttpContext.Session.SetString(CompDraftKey, JsonSerializer.Serialize(draft));

    private async Task<List<MotorVehicleClassOption>> GetVehicleClassesAsync()
    {
        var result = await _apiClient.GetAsync<List<MotorVehicleClassOption>>("/api/products/motor-vehicle-classes");
        return result.Success ? result.Data ?? new List<MotorVehicleClassOption>() : new List<MotorVehicleClassOption>();
    }

    private async Task<List<PeriodOption>> GetPeriodsAsync()
    {
        var result = await _apiClient.GetAsync<List<PeriodOption>>("/api/products/periods");
        return result.Success ? result.Data ?? new List<PeriodOption>() : new List<PeriodOption>();
    }
}
