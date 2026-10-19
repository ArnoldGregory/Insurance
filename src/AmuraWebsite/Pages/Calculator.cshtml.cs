using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages;

/// <summary>
/// Motor premium calculator - an estimate-only page (no client, vehicle or
/// purchase is created). Reuses the same live pricing endpoints as the buy
/// journey: TPO by vehicle class + period (+ carry capacity or tonnage), and
/// the comprehensive value-band comparison. "Buy" links hand off to the
/// existing Motor Details page, which does the real purchase.
/// </summary>
public class CalculatorModel : PageModel
{
    private readonly IMotorPurchaseClient _client;

    public CalculatorModel(IMotorPurchaseClient client)
    {
        _client = client;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    public List<VehicleClassDto> VehicleClasses { get; set; } = new();
    public List<PeriodDto> Periods { get; set; } = new();

    public List<TpoPriceOptionDto>? TpoOptions { get; set; }
    public ComprehensiveQuoteResponse? ComprehensiveQuote { get; set; }

    public bool HasCalculated { get; set; }
    public string? ErrorMessage { get; set; }
    public string? TpoMessage { get; set; }
    public string? ComprehensiveMessage { get; set; }
    public bool IsConfigured => _client.IsConfigured;

    public VehicleClassDto? SelectedClass =>
        VehicleClasses.Find(c => c.VehicleClassId == Input.VehicleClassId);

    public async Task<IActionResult> OnGetAsync()
    {
        if (!_client.IsConfigured)
        {
            ErrorMessage = "The premium calculator isn't available right now - please contact us for a quote.";
            return Page();
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
        if (!_client.IsConfigured)
        {
            ErrorMessage = "The premium calculator isn't available right now - please contact us for a quote.";
            return Page();
        }

        await LoadCatalogAsync();

        var selected = SelectedClass;
        if (selected is null)
        {
            ModelState.AddModelError("Input.VehicleClassId", "Please choose a vehicle class.");
        }
        else if (selected.RequiresTonnage && Input.Tonnage is null)
        {
            ModelState.AddModelError("Input.Tonnage", $"\"{selected.Name}\" is priced by tonnage - please enter the vehicle's tonnage.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        HasCalculated = true;

        // --- Third Party Only ---
        var carry = selected!.RequiresTonnage ? null : Input.CarryCapacity?.ToString();
        var tonnage = selected.RequiresTonnage ? Input.Tonnage : null;
        TpoOptions = await _client.GetTpoQuoteAsync(Input.VehicleClassId, Input.PeriodId, carry, tonnage);
        if (TpoOptions is null)
        {
            TpoMessage = "We couldn't get Third Party prices right now. Please try again shortly.";
        }
        else if (TpoOptions.Count == 0)
        {
            TpoMessage = "None of our underwriters offers Third Party cover for this vehicle class and period online yet - contact us for a quote.";
        }
        else
        {
            TpoOptions = TpoOptions.OrderBy(o => o.Price).ToList();
        }

        // --- Comprehensive (only when a value was entered) ---
        if (Input.VehicleValue is decimal value)
        {
            ComprehensiveQuote = await _client.GetComprehensiveCompareAsync(value);
            if (ComprehensiveQuote is null)
            {
                ComprehensiveMessage = "We couldn't get Comprehensive prices right now. Please try again shortly.";
            }
            else if (ComprehensiveQuote.Options.Count == 0)
            {
                ComprehensiveMessage = "No underwriter covers this vehicle value online - contact us for a quote.";
            }
            else
            {
                ComprehensiveQuote.Options = ComprehensiveQuote.Options.OrderBy(o => o.TotalPremium).ToList();
            }
        }

        return Page();
    }

    private async Task LoadCatalogAsync()
    {
        VehicleClasses = await _client.GetVehicleClassesAsync() ?? new();
        Periods = await _client.GetPeriodsAsync() ?? new();
    }

    public class FormInput
    {
        [Required(ErrorMessage = "Please choose a vehicle class.")]
        [Range(1, int.MaxValue, ErrorMessage = "Please choose a vehicle class.")]
        [Display(Name = "Vehicle class")]
        public int VehicleClassId { get; set; }

        [Required(ErrorMessage = "Please choose a cover period.")]
        [Range(1, int.MaxValue, ErrorMessage = "Please choose a cover period.")]
        [Display(Name = "Cover period")]
        public int PeriodId { get; set; }

        [Range(1, 200, ErrorMessage = "Enter between 1 and 200 passengers.")]
        [Display(Name = "Licensed to carry (passengers)")]
        public int? CarryCapacity { get; set; }

        [Range(0.1, 200, ErrorMessage = "Enter a tonnage between 0.1 and 200.")]
        [Display(Name = "Tonnage")]
        public decimal? Tonnage { get; set; }

        [Range(10000, 100000000, ErrorMessage = "Enter a vehicle value between 10,000 and 100,000,000.")]
        [Display(Name = "Vehicle value (KES)")]
        public decimal? VehicleValue { get; set; }
    }
}
