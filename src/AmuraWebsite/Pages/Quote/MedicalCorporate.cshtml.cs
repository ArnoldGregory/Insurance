using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class MedicalCorporateModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public MedicalCorporateModel(IQuoteSubmissionService submissions)
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
            Type = SubmissionType.MedicalCorporate,
            ContactName = Input.ContactPerson,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,
                ["CompanyName"] = Input.CompanyName,
                ["NumberOfEmployees"] = Input.NumberOfEmployees.ToString(),
                ["CoverLevel"] = Input.CoverLevel
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(160)]
        public string CompanyName { get; set; } = string.Empty;

        [Required, StringLength(120)]
        public string ContactPerson { get; set; } = string.Empty;

        [Required, StringLength(40)]  // ← ADD THIS
        public string IdNo { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [Range(1, 100000)]
        public int NumberOfEmployees { get; set; } = 1;

        [Required]
        public string CoverLevel { get; set; } = "Standard";

        public string? Website { get; set; }
    }
}