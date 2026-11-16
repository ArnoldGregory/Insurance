using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class WibaModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public WibaModel(IQuoteSubmissionService submissions)
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
            Type = SubmissionType.Wiba,
            ContactName = Input.ContactPerson,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["CompanyName"] = Input.CompanyName,
                ["Industry"] = Input.Industry,
                ["EmployeeCount"] = Input.EmployeeCount.ToString(),
                ["AnnualPayroll"] = Input.AnnualPayroll ?? string.Empty,
                ["CoverStartDate"] = Input.CoverStartDate?.ToString("yyyy-MM-dd") ?? string.Empty
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(160)]
        [Display(Name = "Company / organisation name")]
        public string CompanyName { get; set; } = string.Empty;

        [Required, StringLength(120)]
        [Display(Name = "Contact person")]
        public string ContactPerson { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [Required, StringLength(120)]
        [Display(Name = "Industry / sector")]
        public string Industry { get; set; } = string.Empty;

        [Range(1, 100000, ErrorMessage = "Enter the number of employees.")]
        [Display(Name = "Number of employees")]
        public int EmployeeCount { get; set; } = 1;

        [StringLength(60)]
        [Display(Name = "Annual payroll (KES, optional)")]
        public string? AnnualPayroll { get; set; }

        [DataType(DataType.Date)]
        [Display(Name = "Preferred cover start date")]
        public DateTime? CoverStartDate { get; set; }

        public string? Website { get; set; }
    }
}
