using AmuraWebsite.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace AmuraWebsite.Pages.Quote;

public class DomesticModel : PageModel
{
    private readonly IQuoteSubmissionService _submissions;
    private readonly IWebHostEnvironment _env;

    public DomesticModel(IQuoteSubmissionService submissions, IWebHostEnvironment env)
    {
        _submissions = submissions;
        _env = env;
    }

    [BindProperty]
    public FormInput Input { get; set; } = new();

    /// <summary>Optional completed proposal form (Excel/CSV/PDF) the customer downloads, fills and re-uploads.</summary>
    [BindProperty]
    public IFormFile? ProposalFile { get; set; }

    public bool Submitted { get; set; }
    public string? ReferenceNumber { get; set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        var submission = new QuoteSubmission
        {
            Type = SubmissionType.Domestic,
            ContactName = Input.FullName,
            ContactEmail = Input.Email,
            ContactPhone = Input.Phone,
            Details = new()
            {
                ["IdNo"] = Input.IdNo,
                ["PropertyAddress"] = Input.PropertyAddress,
                ["PropertyType"] = Input.PropertyType,
                ["EstimatedValue"] = Input.EstimatedValue
            }
        };

        if (ProposalFile is { Length: > 0 })
        {
            var uploads = Path.Combine(_env.ContentRootPath, "App_Data", "uploads", "domestic");
            Directory.CreateDirectory(uploads);
            var safeName = Path.GetFileName(ProposalFile.FileName);
            var storedPath = Path.Combine(uploads, $"{DateTime.UtcNow:yyyyMMddHHmmssfff}_{safeName}");
            await using (var stream = System.IO.File.Create(storedPath))
            {
                await ProposalFile.CopyToAsync(stream);
            }
            submission.Details["ProposalFileName"] = safeName;
            submission.Details["ProposalStoredPath"] = storedPath;
        }

        ReferenceNumber = await _submissions.SubmitAsync(submission);
        Submitted = true;
        return Page();
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

        [Required, StringLength(250)]
        public string PropertyAddress { get; set; } = string.Empty;

        [Required]
        public string PropertyType { get; set; } = "House";

        [Required, StringLength(60)]
        public string EstimatedValue { get; set; } = string.Empty;
    }
}