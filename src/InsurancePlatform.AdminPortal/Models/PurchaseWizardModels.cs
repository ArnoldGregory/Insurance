using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

// ---- Reference-data mirrors (dropdown sources) -------------------------

/// <summary>Mirrors InsurancePlatform.Domain.Entities.MotorVehicleClass. RequiresTonnage decides whether Step 1 asks for Tonnage or Carry Capacity.</summary>
public class MotorVehicleClassOption
{
    public long VehicleClassId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool RequiresTonnage { get; set; }
    public int? PolicyLevelId { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Period.</summary>
public class PeriodOption
{
    public long PeriodId { get; set; }
    public string Name { get; set; } = string.Empty;
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Product - only used to resolve the single "Motor" product's ProductId for CreatePurchaseRequest.</summary>
public class ProductOption
{
    public long ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string PricingMethod { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.TpoPriceOption - GET /api/pricing/tpo's row shape ("every underwriter currently pricing this combination, cheapest first").</summary>
public class TpoQuoteOption
{
    public long TpoPriceId { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal Price { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.ComprehensiveRateBandOption - one underwriter's pricing for a given vehicle value.</summary>
public class ComprehensiveQuoteOption
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public decimal BasePremium { get; set; }
    public decimal PvtAmount { get; set; }
    public decimal TotalPremium { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.ComprehensiveBenefitItem - one optional benefit.</summary>
public class ComprehensiveBenefitOption
{
    public long BenefitId { get; set; }
    public string BenefitCode { get; set; } = string.Empty;
    public string BenefitName { get; set; } = string.Empty;
    public decimal DefaultPrice { get; set; }
    public bool IsIncludedInBase { get; set; }
    public string? Description { get; set; }
}

public class LiabilityLimitItem
{
    public long LiabilityLimitId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}

/// <summary>The full compare response: options + benefits keyed by underwriter.</summary>
public class ComprehensiveCompareResult
{
    public List<ComprehensiveQuoteOption> Options { get; set; } = new();
    public Dictionary<string, List<ComprehensiveBenefitOption>> BenefitsByUnderwriter { get; set; } = new();
    public Dictionary<string, List<LiabilityLimitItem>> LiabilityLimitsByUnderwriter { get; set; } = new();
}

// ---- Wizard draft (JSON-serialized into TempData between steps) --------

/// <summary>
/// Carries the in-progress purchase across all 4 wizard steps. This app
/// deliberately avoids server-side session state (see Program.cs's cookie-
/// auth comment) - so instead of ASP.NET Session, the draft is JSON-
/// serialized into TempData (cookie-backed) on every step that changes it,
/// and read back + re-kept on every GET via PurchaseWizardController's
/// LoadDraft/SaveDraft helpers. ClientId/VehicleId are filled in as soon as
/// each succeeds during Step 2's save (not only at the very end) so that if
/// Purchase creation itself fails, retrying Step 2 doesn't create a
/// duplicate Client/Vehicle - only the still-missing piece is retried.
/// </summary>
public class PurchaseWizardDraft
{
    // Step 1 - quote
    public long? VehicleClassId { get; set; }
    public string? VehicleClassName { get; set; }
    public bool RequiresTonnage { get; set; }
    public long? PeriodId { get; set; }
    public string? PeriodName { get; set; }
    public string? CarryCapacity { get; set; }
    public decimal? Tonnage { get; set; }
    public long? SelectedTpoPriceId { get; set; }
    public long? SelectedUnderwriterId { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedPremium { get; set; }

    /// <summary>
    /// The full underwriter comparison list from the last "Generate quote"
    /// call - persisted so navigating Step2 -> Step1 ("Back") redraws the
    /// same options (and the previously-picked card) instead of showing an
    /// empty comparison grid. Cleared whenever a fresh quote is generated
    /// (see Step1Generate) since a new vehicle class/period/tonnage
    /// combination invalidates the old prices.
    /// </summary>
    public List<TpoQuoteOption>? QuoteOptions { get; set; }

    // Step 2 - client, vehicle, and the save outcome
    public string? ClientIdNo { get; set; }
    public string? ClientFullName { get; set; }
    public DateTime? ClientDob { get; set; }
    public string? ClientEmail { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientAddress { get; set; }
    public string? ClientKraPin { get; set; }
    public long? ClientId { get; set; }

    public string? VehicleRegNo { get; set; }
    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }
    public string? VehicleChassisNo { get; set; }
    public string? VehicleEngineNo { get; set; }
    public int? VehicleYearOfManufacture { get; set; }
    public string? VehicleBodyType { get; set; }
    public string? VehicleFuelType { get; set; }
    public decimal? VehicleValue { get; set; }
    public long? LicensedToCarry { get; set; }
    public string? AntiTheft { get; set; }
    public string? Risk { get; set; }
    public long? VehicleId { get; set; }

    public DateTime? StartDate { get; set; }

    // Purchase creation outcome
    public long? PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime? EndDate { get; set; }
    public string? AccountNumber { get; set; }
    public string? PaybillNumber { get; set; }

    public bool HasQuoteSelection => VehicleClassId is not null && PeriodId is not null && SelectedUnderwriterId is not null && SelectedPremium is not null;
    public bool HasPurchase => PurchaseId is not null;
}

/// <summary>
/// Separate draft for the Comprehensive wizard - independent from TPO so
/// both flows can run in parallel without clobbering each other's TempData.
/// </summary>
public class ComprehensiveWizardDraft
{
    // Step 1 - compare
    public decimal? VehicleValue { get; set; }
    public List<ComprehensiveQuoteOption>? CompareOptions { get; set; }
    public Dictionary<string, List<ComprehensiveBenefitOption>>? BenefitsByUnderwriter { get; set; }
    public Dictionary<string, List<LiabilityLimitItem>>? LiabilityLimitsByUnderwriter { get; set; }
    public long? SelectedUnderwriterId { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedBasePremium { get; set; }
    public decimal? SelectedTotalPremium { get; set; }
    public string? SelectedBenefitCodes { get; set; }

    // Step 2 - class, period, client, vehicle (collected after underwriter pick)
    public long? VehicleClassId { get; set; }
    public string? VehicleClassName { get; set; }
    public long? PeriodId { get; set; }
    public string? PeriodName { get; set; }

    public string? ClientIdNo { get; set; }
    public string? ClientFullName { get; set; }
    public DateTime? ClientDob { get; set; }
    public string? ClientEmail { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientAddress { get; set; }
    public string? ClientKraPin { get; set; }
    public long? ClientId { get; set; }

    public string? VehicleRegNo { get; set; }
    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }
    public string? VehicleChassisNo { get; set; }
    public string? VehicleEngineNo { get; set; }
    public int? VehicleYearOfManufacture { get; set; }
    public string? VehicleBodyType { get; set; }
    public string? VehicleFuelType { get; set; }
    public long? LicensedToCarry { get; set; }
    public string? AntiTheft { get; set; }
    public string? Risk { get; set; }
    public long? VehicleId { get; set; }
    public DateTime? StartDate { get; set; }

    // Purchase outcome
    public long? PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime? EndDate { get; set; }
    public string? AccountNumber { get; set; }
    public string? PaybillNumber { get; set; }

    public bool HasSelection => SelectedUnderwriterId is not null && SelectedTotalPremium is not null;
    public bool HasDetails => VehicleClassId is not null && PeriodId is not null && ClientIdNo is not null && VehicleRegNo is not null;
    public bool HasPurchase => PurchaseId is not null;
}

// ---- Per-step view models ------------------------------------------------

public class WizardStep1ViewModel
{
    public List<MotorVehicleClassOption> VehicleClasses { get; set; } = new();
    public List<PeriodOption> Periods { get; set; } = new();

    public long? VehicleClassId { get; set; }
    public long? PeriodId { get; set; }
    public string? CarryCapacity { get; set; }
    public decimal? Tonnage { get; set; }

    /// <summary>Populated after "Generate Quote" - null before the first attempt.</summary>
    public List<TpoQuoteOption>? QuoteOptions { get; set; }

    public long? SelectedTpoPriceId { get; set; }
    public string? ErrorMessage { get; set; }
}

public class WizardStep2ViewModel
{
    // Read-only recap of the Step 1 selection
    public string? VehicleClassName { get; set; }
    public string? PeriodName { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedPremium { get; set; }

    [Required(ErrorMessage = "Client ID number is required.")]
    [Display(Name = "Client ID Number")]
    public string ClientIdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Client full name is required.")]
    [Display(Name = "Client full name")]
    public string ClientFullName { get; set; } = string.Empty;

    [DataType(DataType.Date)]
    [Display(Name = "Date of birth")]
    public DateTime? ClientDob { get; set; }

    [EmailAddress]
    public string? ClientEmail { get; set; }

    [Required(ErrorMessage = "Client phone number is required.")]
    [Display(Name = "Client phone")]
    public string ClientPhone { get; set; } = string.Empty;

    public string? ClientAddress { get; set; }

    [Display(Name = "KRA PIN")]
    public string? ClientKraPin { get; set; }

    [Required(ErrorMessage = "Vehicle registration number is required.")]
    [Display(Name = "Registration number")]
    public string VehicleRegNo { get; set; } = string.Empty;

    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }

    [Display(Name = "Chassis number")]
    public string? VehicleChassisNo { get; set; }

    [Display(Name = "Engine number")]
    public string? VehicleEngineNo { get; set; }

    [Display(Name = "Year of manufacture")]
    public int? VehicleYearOfManufacture { get; set; }

    [Display(Name = "Body type")]
    public string? VehicleBodyType { get; set; }

    [Display(Name = "Fuel type")]
    public string? VehicleFuelType { get; set; }

    [Display(Name = "Vehicle value (optional)")]
    public decimal? VehicleValue { get; set; }

    [Display(Name = "Licensed to carry (optional, PSV)")]
    public long? LicensedToCarry { get; set; }

    [Display(Name = "Anti-theft device (optional)")]
    public string? AntiTheft { get; set; }

    [Display(Name = "Risk notes (optional)")]
    public string? Risk { get; set; }

    [Required(ErrorMessage = "Cover start date is required.")]
    [DataType(DataType.Date)]
    [Display(Name = "Cover start date")]
    public DateTime StartDate { get; set; } = DateTime.Today;

    public string? ErrorMessage { get; set; }
}

public class WizardStep3ViewModel
{
    public long PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public DateTime? EndDate { get; set; }
    public string AccountNumber { get; set; } = string.Empty;
    public string PaybillNumber { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }

    public List<PaymentItem> PaymentAttempts { get; set; } = new();
    public bool IsPaid { get; set; }

    [Display(Name = "M-Pesa phone number")]
    public string? MpesaPhoneNumber { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

public class WizardStep4ViewModel
{
    public PurchaseDetail Purchase { get; set; } = new();
    public string ClientName { get; set; } = string.Empty;
}

// ---- Comprehensive wizard view models ------------------------------------

public class ComprehensiveStep1ViewModel
{
    [Required(ErrorMessage = "Vehicle value is required.")]
    [Display(Name = "Vehicle value (KES)")]
    public decimal? VehicleValue { get; set; }

    public List<ComprehensiveQuoteOption>? CompareOptions { get; set; }
    public Dictionary<string, List<ComprehensiveBenefitOption>>? BenefitsByUnderwriter { get; set; }
    public Dictionary<string, List<LiabilityLimitItem>>? LiabilityLimitsByUnderwriter { get; set; }

    public long? SelectedUnderwriterId { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedTotalPremium { get; set; }

    public string? ErrorMessage { get; set; }
}

public class ComprehensiveStep2ViewModel
{
    // Read-only recap of the Step 1 selection
    public decimal? VehicleValue { get; set; }
    public string? SelectedUnderwriterName { get; set; }
    public decimal? SelectedTotalPremium { get; set; }
    public string? SelectedBenefitCodes { get; set; }

    public List<MotorVehicleClassOption> VehicleClasses { get; set; } = new();
    public List<PeriodOption> Periods { get; set; } = new();

    [Required(ErrorMessage = "Vehicle class is required.")]
    [Display(Name = "Vehicle class")]
    public long? VehicleClassId { get; set; }

    [Required(ErrorMessage = "Period is required.")]
    [Display(Name = "Period")]
    public long? PeriodId { get; set; }

    [Required(ErrorMessage = "Client ID number is required.")]
    [Display(Name = "Client ID Number")]
    public string ClientIdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Client full name is required.")]
    [Display(Name = "Client full name")]
    public string ClientFullName { get; set; } = string.Empty;

    [DataType(DataType.Date)]
    [Display(Name = "Date of birth")]
    public DateTime? ClientDob { get; set; }

    [EmailAddress]
    public string? ClientEmail { get; set; }

    [Required(ErrorMessage = "Client phone number is required.")]
    [Display(Name = "Client phone")]
    public string ClientPhone { get; set; } = string.Empty;

    public string? ClientAddress { get; set; }

    [Display(Name = "KRA PIN")]
    public string? ClientKraPin { get; set; }

    [Required(ErrorMessage = "Vehicle registration number is required.")]
    [Display(Name = "Registration number")]
    public string VehicleRegNo { get; set; } = string.Empty;

    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }

    [Display(Name = "Chassis number")]
    public string? VehicleChassisNo { get; set; }

    [Display(Name = "Engine number")]
    public string? VehicleEngineNo { get; set; }

    [Display(Name = "Year of manufacture")]
    public int? VehicleYearOfManufacture { get; set; }

    [Display(Name = "Body type")]
    public string? VehicleBodyType { get; set; }

    [Display(Name = "Fuel type")]
    public string? VehicleFuelType { get; set; }

    [Display(Name = "Licensed to carry (optional, PSV)")]
    public long? LicensedToCarry { get; set; }

    [Display(Name = "Anti-theft device (optional)")]
    public string? AntiTheft { get; set; }

    [Display(Name = "Risk notes (optional)")]
    public string? Risk { get; set; }

    [Required(ErrorMessage = "Cover start date is required.")]
    [DataType(DataType.Date)]
    [Display(Name = "Cover start date")]
    public DateTime StartDate { get; set; } = DateTime.Today;

    public string? ErrorMessage { get; set; }
}

// ---- Small deserialization targets for the 3 write calls Step 2 makes ---

/// <summary>Matches POST /api/clients's success payload: new { ClientId = ... }.</summary>
public class ClientIdResult
{
    public long ClientId { get; set; }
}

/// <summary>
/// Matches both GET /api/vehicles/by-reg-no/{regNo}'s Vehicle payload
/// (dedup lookup - only VehicleId is used from it) and POST /api/clients/
/// {clientId}/vehicles's success payload new { VehicleId = ... }. Extra
/// fields present on the Vehicle entity but not declared here are simply
/// ignored by System.Text.Json.
/// </summary>
public class VehicleIdResult
{
    public long VehicleId { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.PurchaseCreateResult - POST /api/purchases's success payload.</summary>
public class PurchaseCreateResultData
{
    public long PurchaseId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
    public DateTime EndDate { get; set; }
    public string AccountNumber { get; set; } = string.Empty;
    public string PaybillNumber { get; set; } = string.Empty;
}

/// <summary>Matches both branches of POST /api/payments/stk-push's response shape (PushSent=false has PushMessage; PushSent=true has MerchantRequestId/CheckoutRequestId instead) - all fields nullable/optional so either shape deserializes cleanly.</summary>
public class StkPushResultData
{
    public long PaymentId { get; set; }
    public bool PushSent { get; set; }
    public string? PushMessage { get; set; }
    public string? MerchantRequestId { get; set; }
    public string? CheckoutRequestId { get; set; }
}
