using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote.Motor;

public class CompareModel : PageModel
{
    private readonly IMotorPurchaseClient _client;
    private readonly MotorSessionStore _sessionStore;

    public CompareModel(IMotorPurchaseClient client, MotorSessionStore sessionStore)
    {
        _client = client;
        _sessionStore = sessionStore;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    public MotorSessionState State { get; set; } = new();
    public string? ErrorMessage { get; set; }

    public IActionResult OnGet()
    {
        State = _sessionStore.Get(HttpContext.Session);
        if (State.ClientId is null || State.VehicleId is null)
        {
            // Session expired or someone jumped straight to this page.
            return RedirectToPage("Details");
        }

        if (State.CoverType == "COMPREHENSIVE")
        {
            if (State.ComprehensiveQuote is null || State.ComprehensiveQuote.Options.Count == 0)
            {
                return RedirectToPage("Details");
            }
        }
        else if (State.PriceOptions.Count == 0)
        {
            return RedirectToPage("Details");
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        State = _sessionStore.Get(HttpContext.Session);
        if (State.ClientId is null || State.VehicleId is null)
        {
            return RedirectToPage("Details");
        }

        bool isComprehensive = State.CoverType == "COMPREHENSIVE";

        decimal chosenPrice;
        if (isComprehensive)
        {
            var chosen = State.ComprehensiveQuote?.Options.FirstOrDefault(p => p.UnderwriterId == Input.UnderwriterId);
            if (chosen is null)
            {
                ErrorMessage = "Please select one of the price options below.";
                return Page();
            }
            // If the user came from the quote page with benefits selected, honour that price.
            chosenPrice = State.SelectedUnderwriterId == Input.UnderwriterId && State.SelectedPrice.HasValue
                ? State.SelectedPrice.Value
                : chosen.TotalPremium;
            State.SelectedUnderwriterName = chosen.UnderwriterName;
        }
        else
        {
            var chosen = State.PriceOptions.FirstOrDefault(p => p.UnderwriterId == Input.UnderwriterId);
            if (chosen is null)
            {
                ErrorMessage = "Please select one of the price options below.";
                return Page();
            }
            chosenPrice = chosen.Price;
            State.SelectedUnderwriterName = chosen.UnderwriterName;
        }

        if (State.ProductId is null)
        {
            ErrorMessage = "We couldn't identify the motor product to purchase. Please contact us directly.";
            return Page();
        }

        var purchase = isComprehensive
            ? await _client.CreateComprehensivePurchaseAsync(
                State.ProductId.Value, State.ClientId.Value, Input.UnderwriterId, chosenPrice,
                State.PeriodId, DateTime.UtcNow.Date, State.VehicleId.Value, State.VehicleValue)
            : await _client.CreatePurchaseAsync(
                State.ProductId.Value, State.ClientId.Value, Input.UnderwriterId, chosenPrice,
                State.PeriodId, DateTime.UtcNow.Date, State.VehicleId.Value, State.CarryCapacity);

        if (purchase is null)
        {
            ErrorMessage = "We couldn't create your purchase right now. Please try again, or contact us directly.";
            return Page();
        }

        State.SelectedUnderwriterId = Input.UnderwriterId;
        State.SelectedPrice = chosenPrice;
        State.PurchaseId = purchase.PurchaseId;
        State.PolicyNumber = purchase.PolicyNumber;
        State.AccountNumber = purchase.AccountNumber;
        State.PaybillNumber = purchase.PaybillNumber;

        _sessionStore.Save(HttpContext.Session, State);
        return RedirectToPage("Pay");
    }

    public class FormInput
    {
        [Required(ErrorMessage = "Please select a price option.")]
        public int UnderwriterId { get; set; }
    }
}
