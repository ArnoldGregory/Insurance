using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace AmuraWebsite.Pages.Quote;

public class MedicalIndividualModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;

    public MedicalIndividualModel(IQuoteSubmissionService submissions)
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
        var dependentRows = Input.Dependents ?? new List<DependentInput>();
        var spouseCount = dependentRows.Count(d => d.Relationship == "Spouse" && !string.IsNullOrWhiteSpace(d.FullName));
        if (spouseCount > 1)
        {
            ModelState.AddModelError(string.Empty, "Only one spouse can be listed per quote.");
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

        var familyMembers = dependentRows
            .Where(d => !string.IsNullOrWhiteSpace(d.FullName) && d.Relationship != "None" && d.DateOfBirth.HasValue)
            .Select(d => new { relationship = d.Relationship, fullName = d.FullName!, dateOfBirth = d.DateOfBirth!.Value.ToString("yyyy-MM-dd") })
            .ToList();

        // Real platform API only knows clientName as one string — build it
        // from the split name fields for that call, while still keeping
        // First/Last/Other separately in our own local record below.
        var fullName = string.Join(" ", new[] { Input.FirstName, Input.OtherNames, Input.LastName }
            .Where(s => !string.IsNullOrWhiteSpace(s)));

        var submission = new QuoteSubmission
        {
            Type = SubmissionType.MedicalIndividual,
            ContactName = fullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.MobileNumber,
            Details = new()
            {
                ["FirstName"] = Input.FirstName,
                ["LastName"] = Input.LastName,
                ["OtherNames"] = Input.OtherNames ?? string.Empty,
                ["IdNo"] = Input.IdNo,
                ["DateOfBirth"] = Input.DateOfBirth!.Value.ToString("yyyy-MM-dd"),
                ["FamilyMembersJson"] = JsonSerializer.Serialize(familyMembers),

                // Local-only fields — not part of the real platform API's
                // confirmed schema, kept here for staff to see when pricing
                // the quote manually.
                ["InpatientLimit"] = Input.InpatientLimit,
                ["OutpatientEnabled"] = Input.OutpatientEnabled.ToString(),
                ["OutpatientLimit"] = Input.OutpatientEnabled ? (Input.OutpatientLimit ?? string.Empty) : string.Empty,
                ["DentalEnabled"] = Input.DentalEnabled.ToString(),
                ["DentalLimit"] = Input.DentalEnabled ? (Input.DentalLimit ?? string.Empty) : string.Empty,
                ["MaternityEnabled"] = Input.MaternityEnabled.ToString()
            }
        };

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
    }

    public class DependentInput
    {
        public string Relationship { get; set; } = "None";
        public string? FullName { get; set; }
        public DateTime? DateOfBirth { get; set; }
    }

    // Field set matches the real platform's medical-individual contract
    // (idNo, clientDob, email, phone, familyMembers) plus split name fields
    // and coverage-preference fields the client asked for on top — those
    // extras are local-only, see the comment in OnPostAsync above.
    public class FormInput
    {
        [Required, StringLength(60)]
        public string FirstName { get; set; } = string.Empty;

        [Required, StringLength(60)]
        public string LastName { get; set; } = string.Empty;

        [StringLength(60)]
        public string? OtherNames { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, Phone]
        [Display(Name = "Mobile number")]
        public string MobileNumber { get; set; } = string.Empty;

        [Required, StringLength(40)]
        [Display(Name = "National ID / Passport number")]
        public string IdNo { get; set; } = string.Empty;

        [Required(ErrorMessage = "Date of birth is required."), DataType(DataType.Date)]
        public DateTime? DateOfBirth { get; set; }

        [Required]
        [Display(Name = "Inpatient limit")]
        public string InpatientLimit { get; set; } = "1000000";

        [Display(Name = "Outpatient cover")]
        public bool OutpatientEnabled { get; set; }
        public string? OutpatientLimit { get; set; }

        [Display(Name = "Dental cover")]
        public bool DentalEnabled { get; set; }
        public string? DentalLimit { get; set; }

        [Display(Name = "Maternity cover")]
        public bool MaternityEnabled { get; set; }

        // Unlimited dependants — starts with one empty row; the page's
        // script appends another automatically each time the last row's
        // relationship is set to Spouse or Child. Standard ASP.NET Core
        // list binding: Input.Dependents[0].FullName, [1].FullName, etc.
        public List<DependentInput> Dependents { get; set; } = new() { new DependentInput() };

        // Honeypot — real users never see or fill this in.
        public string? Website { get; set; }
    }
}
