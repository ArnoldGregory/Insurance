using System.ComponentModel.DataAnnotations;
using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AmuraWebsite.Pages.Quote.Motor;

public class CertificateModel : PageModel
{
    private readonly IMotorPurchaseClient _client;
    private readonly MotorSessionStore _sessionStore;

    public CertificateModel(IMotorPurchaseClient client, MotorSessionStore sessionStore)
    {
        _client = client;
        _sessionStore = sessionStore;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    public ClientCertificateDto? Certificate { get; set; }
    public string? ErrorMessage { get; set; }

    public async Task<IActionResult> OnGetAsync()
    {
        var state = _sessionStore.Get(HttpContext.Session);

        // Just bought a policy in this browser - we already know the
        // purchase, so show its certificate right away.
        if (state.PurchaseId is int purchaseId)
        {
            Certificate = await _client.GetPurchaseCertificateAsync(purchaseId);
            if (Certificate is null)
            {
                ErrorMessage = "We couldn't load your policy right now. Please try again in a moment.";
            }
            return Page();
        }

        // Return visitor with no session - pre-fill the lookup form with
        // whatever the session last knew so it's one field away from done.
        Input.PolicyNumber = state.PolicyNumber ?? string.Empty;
        Input.Phone = state.Phone ?? string.Empty;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        Certificate = await _client.LookupCertificateAsync(Input.PolicyNumber, Input.Phone);

        if (Certificate is null)
        {
            ErrorMessage = "We couldn't find a policy matching that policy number and phone number. Check both and try again.";
        }

        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(100)]
        [Display(Name = "Policy number")]
        public string PolicyNumber { get; set; } = string.Empty;

        [Required, Phone]
        [Display(Name = "Phone number used to pay")]
        public string Phone { get; set; } = string.Empty;
    }
}