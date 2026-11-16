using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class StudentTravelModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public StudentTravelModel(IQuoteSubmissionService submissions)
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
        if (Input.DepartureDate.HasValue && Input.ReturnDate.HasValue && Input.ReturnDate < Input.DepartureDate)
        {
            ModelState.AddModelError(nameof(Input.ReturnDate), "Return date can't be before the departure date.");
        }

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
            Type = SubmissionType.StudentTravel,
            ContactName = Input.FullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,
                ["DateOfBirth"] = Input.DateOfBirth!.Value.ToString("yyyy-MM-dd"),
                ["Institution"] = Input.Institution,
                ["Destination"] = Input.Destination,
                ["DepartureDate"] = Input.DepartureDate!.Value.ToString("yyyy-MM-dd"),
                ["ReturnDate"] = Input.ReturnDate!.Value.ToString("yyyy-MM-dd")
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(120)]
        [Display(Name = "Student full name")]
        public string FullName { get; set; } = string.Empty;

        [Required, StringLength(40)]
        [Display(Name = "National ID / Passport number")]
        public string IdNo { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Date of birth is required."), DataType(DataType.Date)]
        [Display(Name = "Date of birth")]
        public DateTime? DateOfBirth { get; set; }

        [Required, StringLength(160)]
        [Display(Name = "School / institution")]
        public string Institution { get; set; } = string.Empty;

        [Required, StringLength(120)]
        [Display(Name = "Destination")]
        public string Destination { get; set; } = string.Empty;

        [Required(ErrorMessage = "Departure date is required."), DataType(DataType.Date)]
        [Display(Name = "Departure date")]
        public DateTime? DepartureDate { get; set; }

        [Required(ErrorMessage = "Return date is required."), DataType(DataType.Date)]
        [Display(Name = "Return date")]
        public DateTime? ReturnDate { get; set; }

        public string? Website { get; set; }
    }
}
