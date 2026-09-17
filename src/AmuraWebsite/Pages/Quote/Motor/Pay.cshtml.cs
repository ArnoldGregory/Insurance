using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AmuraWebsite.Pages.Quote.Motor;

public class PayModel : PageModel
{
    private readonly IMotorPurchaseClient _client;
    private readonly MotorSessionStore _sessionStore;

    public PayModel(IMotorPurchaseClient client, MotorSessionStore sessionStore)
    {
        _client = client;
        _sessionStore = sessionStore;
    }

    public MotorSessionState State { get; set; } = new();
    public string? ErrorMessage { get; set; }
    public bool PushJustSent { get; set; }

    public IActionResult OnGet()
    {
        State = _sessionStore.Get(HttpContext.Session);
        if (State.PurchaseId is null)
        {
            return RedirectToPage("Details");
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        State = _sessionStore.Get(HttpContext.Session);
        if (State.PurchaseId is null || State.SelectedPrice is null)
        {
            return RedirectToPage("Details");
        }

        var result = await _client.InitiatePaymentAsync(
            State.PurchaseId.Value, State.SelectedPrice.Value, State.Phone,
            State.PolicyNumber ?? State.PurchaseId.Value.ToString());

        if (result is null || !result.PushSent)
        {
            ErrorMessage = "We couldn't send the payment prompt to your phone right now. Please try again in a moment.";
            return Page();
        }

        State.PaymentId = result.PaymentId;
        State.PushSent = true;
        _sessionStore.Save(HttpContext.Session, State);

        PushJustSent = true;
        return Page();
    }
}
