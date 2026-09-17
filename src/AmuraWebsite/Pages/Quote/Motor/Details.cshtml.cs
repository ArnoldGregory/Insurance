using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote.Motor;

public class DetailsModel : PageModel
{
    private readonly IMotorPurchaseClient _client;
    private readonly MotorSessionStore _sessionStore;

    public DetailsModel(IMotorPurchaseClient client, MotorSessionStore sessionStore)
    {
        _client = client;
        _sessionStore = sessionStore;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    // Pre-selections carried over from the comprehensive quote page ("Continue to Buy").
    [BindProperty]
    public int? PreselectedUnderwriterId { get; set; }

    [BindProperty]
    public decimal? PreselectedPrice { get; set; }

    public List<VehicleClassDto> VehicleClasses { get; set; } = new();
    public List<PeriodDto> Periods { get; set; } = new();
    public string? ErrorMessage { get; set; }
    public bool IsConfigured => _client.IsConfigured;

    public async Task<IActionResult> OnGetAsync(string? coverType, decimal? vehicleValue, int? underwriterId, decimal? premium)
    {
        _sessionStore.Clear(HttpContext.Session);

        if (!_client.IsConfigured)
        {
            ErrorMessage = "Motor purchase isn't available right now — please use the Get a Quote form instead, or contact us directly.";
            return Page();
        }

        // Arriving from the comprehensive quote page with a chosen underwriter — pre-fill the form.
        if (coverType == "COMPREHENSIVE" && vehicleValue.HasValue)
        {
            Input.CoverType = "COMPREHENSIVE";
            Input.VehicleValue = vehicleValue;
            PreselectedUnderwriterId = underwriterId;
            PreselectedPrice = premium;
        }

        await LoadCatalogAsync();
        if (VehicleClasses.Count == 0 || Periods.Count == 0)
        {
            ErrorMessage = "We couldn't load vehicle and cover-period options right now. Please try again shortly.";
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        await LoadCatalogAsync();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        // 1. Resolve or create the client record.
        int? clientId = null;
        var resolved = await _client.ResolveClientAsync(Input.IdNo);
        if (resolved?.ClientId is int existingId)
        {
            clientId = existingId;
        }
        else
        {
            clientId = await _client.CreateClientAsync(
                Input.IdNo, Input.FullName, Input.Dob!.Value, Input.Email, Input.Phone,
                Input.Address, Input.KraPin);
        }

        if (clientId is null)
        {
            ErrorMessage = "We couldn't verify your details with our system. Please check them and try again, or contact us directly.";
            return Page();
        }

        // 2. Register the vehicle.
        var vehicleId = await _client.RegisterVehicleAsync(
            clientId.Value, Input.Make, Input.Model, Input.RegNo, Input.ChassisNo, Input.EngineNo,
            Input.YearOfManufacture, Input.VehicleType, Input.BodyType, Input.FuelType,
            Input.CubicCapacity, Input.Color, Input.Logbook);

        if (vehicleId is null)
        {
            ErrorMessage = "We couldn't register your vehicle. Please double-check the registration and chassis numbers and try again.";
            return Page();
        }

        // 3. Get live pricing across underwriters — branch on cover type.
        bool isComprehensive = Input.CoverType == "COMPREHENSIVE";

        decimal vehicleValue = 0;
        if (isComprehensive)
        {
            if (Input.VehicleValue is not decimal val)
            {
                ErrorMessage = "Please enter the vehicle's value to get a comprehensive quote.";
                return Page();
            }
            vehicleValue = val;
        }

        var productId = await _client.GetMotorProductIdAsync();

        var state = new MotorSessionState
        {
            IdNo = Input.IdNo,
            FullName = Input.FullName,
            Dob = Input.Dob!.Value.ToString("yyyy-MM-dd"),
            Email = Input.Email,
            Phone = Input.Phone,
            Address = Input.Address,
            KraPin = Input.KraPin,
            ClientId = clientId,

            Make = Input.Make,
            Model = Input.Model,
            RegNo = Input.RegNo,
            ChassisNo = Input.ChassisNo,
            EngineNo = Input.EngineNo,
            YearOfManufacture = Input.YearOfManufacture,
            VehicleType = Input.VehicleType,
            BodyType = Input.BodyType,
            FuelType = Input.FuelType,
            CubicCapacity = Input.CubicCapacity,
            Color = Input.Color,
            Logbook = Input.Logbook,
            VehicleId = vehicleId,

            VehicleClassId = Input.VehicleClassId,
            PeriodId = Input.PeriodId,
            CarryCapacity = Input.CarryCapacity,
            CoverType = Input.CoverType,
            VehicleValue = isComprehensive ? vehicleValue : 0,
            ProductId = productId
        };

        if (isComprehensive)
        {
            var quote = await _client.GetComprehensiveCompareAsync(vehicleValue);
            if (quote is null || quote.Options.Count == 0)
            {
                ErrorMessage = "We couldn't get a comprehensive quote for this vehicle right now. Please try again shortly, or contact us directly.";
                return Page();
            }
            state.ComprehensiveQuote = quote;
            // Keep the underwriter + price the user picked on the quote page.
            if (PreselectedUnderwriterId.HasValue)
            {
                state.SelectedUnderwriterId = PreselectedUnderwriterId;
                state.SelectedPrice = PreselectedPrice;
            }
        }
        else
        {
            var prices = await _client.GetTpoPricingAsync(Input.VehicleClassId, Input.PeriodId, Input.CarryCapacity);
            if (prices is null || prices.Count == 0)
            {
                ErrorMessage = "We couldn't get pricing for this vehicle right now. Please try again shortly, or contact us directly.";
                return Page();
            }
            state.PriceOptions = prices;
        }

        _sessionStore.Save(HttpContext.Session, state);
        return RedirectToPage("Compare");
    }

    private async Task LoadCatalogAsync()
    {
        VehicleClasses = await _client.GetVehicleClassesAsync() ?? new List<VehicleClassDto>();
        Periods = await _client.GetPeriodsAsync() ?? new List<PeriodDto>();
    }

    // PENDING: vehicleType/bodyType/fuelType option lists below are a
    // reasonable best guess, not confirmed against the platform's actual
    // accepted values — the Postman examples only demonstrate a PSV bus.
    // Verify against the real backend (or ask the platform team for the
    // valid enum list) before relying on these in production.
    public class FormInput
    {
        [Required, StringLength(40)]
        [Display(Name = "National ID / Passport number")]
        public string IdNo { get; set; } = string.Empty;

        [Required, StringLength(120)]
        [Display(Name = "Full name")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Date of birth is required."), DataType(DataType.Date)]
        public DateTime? Dob { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [StringLength(200)]
        public string? Address { get; set; }

        [StringLength(20)]
        [Display(Name = "KRA PIN (optional)")]
        public string? KraPin { get; set; }

        [Required, StringLength(60)]
        public string Make { get; set; } = string.Empty;

        [Required, StringLength(60)]
        public string Model { get; set; } = string.Empty;

        [Required, StringLength(20)]
        [Display(Name = "Registration number")]
        public string RegNo { get; set; } = string.Empty;

        [Required, StringLength(60)]
        [Display(Name = "Chassis number")]
        public string ChassisNo { get; set; } = string.Empty;

        [Required, StringLength(60)]
        [Display(Name = "Engine number")]
        public string EngineNo { get; set; } = string.Empty;

        [Required, Range(1980, 2027)]
        [Display(Name = "Year of manufacture")]
        public int YearOfManufacture { get; set; } = DateTime.UtcNow.Year;

        [Required]
        [Display(Name = "Vehicle type")]
        public string VehicleType { get; set; } = "PRIVATE";

        [Required]
        [Display(Name = "Body type")]
        public string BodyType { get; set; } = "SALOON";

        [Required]
        [Display(Name = "Fuel type")]
        public string FuelType { get; set; } = "PETROL";

        [Required, StringLength(20)]
        [Display(Name = "Cubic capacity (cc)")]
        public string CubicCapacity { get; set; } = string.Empty;

        [Required, StringLength(30)]
        public string Color { get; set; } = string.Empty;

    [Required, StringLength(60)]
    [Display(Name = "Logbook number")]
    public string Logbook { get; set; } = string.Empty;

    [Required]
    [Display(Name = "Vehicle class")]
    public int VehicleClassId { get; set; }

    [Required]
    [Display(Name = "Cover period")]
    public int PeriodId { get; set; }

    [Required, Range(1, 100)]
    [Display(Name = "Number licensed to carry")]
    public int CarryCapacity { get; set; } = 1;

    [Required]
    [Display(Name = "Cover type")]
    public string CoverType { get; set; } = "TPO";

    [Range(10000, 100000000, ErrorMessage = "Enter a vehicle value between 10,000 and 100,000,000.")]
    [Display(Name = "Vehicle value (KES)")]
    public decimal? VehicleValue { get; set; }
    }
}
