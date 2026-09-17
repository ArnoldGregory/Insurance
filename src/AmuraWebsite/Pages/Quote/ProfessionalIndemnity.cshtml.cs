using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class ProfessionalIndemnityModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public ProfessionalIndemnityModel(IQuoteSubmissionService submissions)
    {
        _submissions = submissions;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    [BindProperty]
    public string FormToken { get; set; } = string.Empty;

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
            return RedirectToPage("/Index");
        }

        var submission = new QuoteSubmission
        {
            Type = SubmissionType.ProfessionalIndemnity,
            ContactName = Input.FullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,
                ["Profession"] = Input.Profession,
                ["YearsInPractice"] = Input.YearsInPractice.ToString()
            }
        };

        var reference = await _submissions.SubmitAsync(submission);

        return RedirectToPage("Proposal", new { reference });
    }

    public class FormInput
    {
        [Required, StringLength(120)]
        public string FullName { get; set; } = string.Empty;

        [Required, StringLength(40)]
        public string IdNo { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [Required, StringLength(160)]
        public string Profession { get; set; } = string.Empty;

        [Range(0, 60)]
        public int YearsInPractice { get; set; }

        public string? Website { get; set; }
    }
}