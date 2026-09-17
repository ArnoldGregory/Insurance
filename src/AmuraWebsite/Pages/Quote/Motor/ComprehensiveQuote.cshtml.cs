using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote.Motor;

public class ComprehensiveQuoteModel : PageModel
{
    private readonly IMotorPurchaseClient _client;

    public ComprehensiveQuoteModel(IMotorPurchaseClient client)
    {
        _client = client;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    [BindProperty]
    public string? SelectedUnderwriter { get; set; }

    [BindProperty]
    public List<string> SelectedBenefits { get; set; } = new();

    public ComprehensiveQuoteResponse? Quote { get; set; }
    public string? ErrorMessage { get; set; }
    public bool IsConfigured => _client.IsConfigured;

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        if (!_client.IsConfigured)
        {
            ErrorMessage = "Comprehensive quotes aren't available right now — please contact us directly.";
            return Page();
        }

        Quote = await _client.GetComprehensiveCompareAsync(Input.VehicleValue);
        if (Quote is null || Quote.Options.Count == 0)
        {
            ErrorMessage = "We couldn't get a comprehensive quote for that vehicle value right now. Please try again shortly, or contact us directly.";
        }

        return Page();
    }

    // User picked an underwriter + benefits on the quote results and wants to buy.
    public async Task<IActionResult> OnPostContinueAsync()
    {
        if (!_client.IsConfigured)
        {
            ErrorMessage = "Comprehensive purchases aren't available right now — please contact us directly.";
            return Page();
        }

        var quote = await _client.GetComprehensiveCompareAsync(Input.VehicleValue);
        if (quote is null || quote.Options.Count == 0)
        {
            ErrorMessage = "We couldn't get a comprehensive quote for that vehicle value right now. Please try again shortly, or contact us directly.";
            return Page();
        }

        if (int.TryParse(SelectedUnderwriter, out var underwriterId) == false)
        {
            ErrorMessage = "Please choose an underwriter to continue.";
            Quote = quote;
            return Page();
        }

        var option = quote.Options.FirstOrDefault(o => o.UnderwriterId == underwriterId);
        if (option is null)
        {
            ErrorMessage = "Please choose one of the underwriters above to continue.";
            Quote = quote;
            return Page();
        }

        // Sum the selected optional benefits for THIS underwriter.
        decimal premium = option.BasePremium + option.PvtAmount;
        if (quote.BenefitsByUnderwriter.TryGetValue(underwriterId.ToString(), out var benefits))
        {
            var selectedKeys = SelectedBenefits.Where(b => b.StartsWith(underwriterId + ":")).ToList();
            foreach (var key in selectedKeys)
            {
                var benefitId = key.Split(':')[1];
                var benefit = benefits.FirstOrDefault(b => b.BenefitId.ToString() == benefitId);
                if (benefit is { IsIncludedInBase: false })
                {
                    premium += benefit.DefaultPrice;
                }
            }
        }

        return RedirectToPage("Details", new
        {
            coverType = "COMPREHENSIVE",
            vehicleValue = Input.VehicleValue,
            underwriterId,
            premium
        });
    }

    public class FormInput
    {
        [Required(ErrorMessage = "Please enter your vehicle's value.")]
        [Range(10000, 100000000, ErrorMessage = "Enter a vehicle value between 10,000 and 100,000,000.")]
        [Display(Name = "Vehicle value (KES)")]
        public decimal VehicleValue { get; set; }
    }
}