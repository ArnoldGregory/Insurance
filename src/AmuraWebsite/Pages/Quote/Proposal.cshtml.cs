using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class ProposalModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public ProposalModel(IQuoteSubmissionService submissions)
    {
        _submissions = submissions;
    }

    [BindProperty(SupportsGet = true)]
    public string Reference { get; set; } = string.Empty;

    [BindProperty]
    public FormInput Input { get; set; } = new();

    [BindProperty]
    public string FormToken { get; set; } = string.Empty;

    public bool Submitted { get; set; }
    public string? ProposalReferenceNumber { get; set; }

    public void OnGet()
    {
        FormToken = SpamGuard.GenerateFormToken();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        if (SpamGuard.LooksLikeSpam(Input.Website, FormToken))
        {
            Submitted = true;
            return Page();
        }

        var submission = new QuoteSubmission
        {
            Type = SubmissionType.ProfessionalIndemnity,
            ContactName = string.Empty,
            ContactEmail = string.Empty,
            Details = new()
            {
                ["Stage"] = "Proposal",
                ["LinkedQuoteReference"] = Reference,
                ["AnnualRevenue"] = Input.AnnualRevenue,
                ["ClaimsHistory"] = Input.ClaimsHistory ?? "None declared",
                ["ScopeOfWork"] = Input.ScopeOfWork
            }
        };

        ProposalReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    // PENDING: confirm the real Professional Indemnity proposal field list
    // against Amura/insurer underwriting requirements.
    public class FormInput
    {
        [Required, StringLength(2000)]
        public string ScopeOfWork { get; set; } = string.Empty;

        [Required, StringLength(60)]
        public string AnnualRevenue { get; set; } = string.Empty;

        [StringLength(2000)]
        public string? ClaimsHistory { get; set; }

        // Honeypot — real users never see or fill this in.
        public string? Website { get; set; }
    }
}
