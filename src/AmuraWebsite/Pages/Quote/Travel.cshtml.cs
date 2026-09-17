using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class TravelModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public TravelModel(IQuoteSubmissionService submissions)
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
            Type = SubmissionType.Travel,
            ContactName = Input.FullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,  // ← ADDED THIS LINE
                ["DateOfBirth"] = Input.DateOfBirth!.Value.ToString("yyyy-MM-dd"),
                ["KraPin"] = Input.KraPin ?? string.Empty,
                ["Destination"] = Input.Destination,
                ["DepartureDate"] = Input.DepartureDate!.Value.ToString("yyyy-MM-dd"),
                ["ReturnDate"] = Input.ReturnDate!.Value.ToString("yyyy-MM-dd"),
                ["TravellingWithFamily"] = Input.TravellingWithFamily.ToString(),
                ["TripType"] = Input.TripType
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class FormInput
    {
        [Required, StringLength(120)]
        public string FullName { get; set; } = string.Empty;

        [Required, StringLength(40)]  // ← ADDED THIS BLOCK
        [Display(Name = "National ID / Passport number")]
        public string IdNo { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Date of birth is required."), DataType(DataType.Date)]
        [Display(Name = "Date of birth")]
        public DateTime? DateOfBirth { get; set; }

        [StringLength(20)]
        [Display(Name = "KRA PIN (optional)")]
        public string? KraPin { get; set; }

        [Required, StringLength(120)]
        public string Destination { get; set; } = string.Empty;

        [Required(ErrorMessage = "Departure date is required."), DataType(DataType.Date)]
        public DateTime? DepartureDate { get; set; }

        [Required(ErrorMessage = "Return date is required."), DataType(DataType.Date)]
        public DateTime? ReturnDate { get; set; }

        [Display(Name = "Travelling with family?")]
        public bool TravellingWithFamily { get; set; }

        [Required]
        public string TripType { get; set; } = "VACATION";

        public string? Website { get; set; }
    }
}