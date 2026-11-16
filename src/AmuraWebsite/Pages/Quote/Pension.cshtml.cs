using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class PensionModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public PensionModel(IQuoteSubmissionService submissions)
    {
        _submissions = submissions;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    [BindProperty]
    public string FormToken { get; set; } = string.Empty;

    public bool Submitted { get; set; }
    public string? ReferenceNumber { get; set; }

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
            Type = SubmissionType.Pension,
            ContactName = Input.FullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,
                ["Employer"] = Input.Employer ?? string.Empty,
                ["PreferredRetirementAge"] = Input.PreferredRetirementAge.ToString(),
                ["MonthlyContribution"] = Input.MonthlyContribution ?? string.Empty
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(120)]
        [Display(Name = "Full name")]
        public string FullName { get; set; } = string.Empty;

        [Required, StringLength(40)]
        [Display(Name = "National ID / Passport number")]
        public string IdNo { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [StringLength(160)]
        [Display(Name = "Employer (optional)")]
        public string? Employer { get; set; }

        [Range(18, 75)]
        [Display(Name = "Preferred retirement age")]
        public int PreferredRetirementAge { get; set; } = 60;

        [StringLength(60)]
        [Display(Name = "Monthly contribution (KES, optional)")]
        public string? MonthlyContribution { get; set; }

        public string? Website { get; set; }
    }
}
