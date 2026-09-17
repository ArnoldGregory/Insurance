using System.Text.Json;

namespace AmuraWebsite.Services;

public sealed class QuoteSubmissionService : IQuoteSubmissionService
{
    private readonly ILogger<QuoteSubmissionService> _logger;
    private readonly IWebHostEnvironment _env;
    private readonly IInsurancePlatformClient _platformClient;
    private readonly SemaphoreSlim _fileLock = new(1, 1);

    public QuoteSubmissionService(
        ILogger<QuoteSubmissionService> logger,
        IWebHostEnvironment env,
        IInsurancePlatformClient platformClient)
    {
        _logger = logger;
        _env = env;
        _platformClient = platformClient;
    }

    public async Task<string> SubmitAsync(QuoteSubmission submission, CancellationToken ct = default)
    {
        submission.ReferenceNumber = GenerateReferenceNumber(submission.Type);
        submission.SubmittedAtUtc = DateTimeOffset.UtcNow;

        if (_platformClient.IsConfigured)
        {
            var platformResult = await TrySubmitToPlatformAsync(submission, ct);
            if (platformResult != null)
            {
                if (platformResult.QuoteRequestId != null)
                {
                    submission.Details["PlatformQuoteRequestId"] = platformResult.QuoteRequestId;
                }
                if (platformResult.RefNo != null)
                {
                    submission.Details["PlatformRefNo"] = platformResult.RefNo;
                }
                _logger.LogInformation(
                    "Submission {Reference} also created on the Insurance Platform as quoteRequestId {PlatformId} (refNo {RefNo}).",
                    submission.ReferenceNumber, platformResult.QuoteRequestId, platformResult.RefNo);
            }
        }

        await PersistAsync(submission, ct);

        _logger.LogInformation(
            "Quote submission {Reference} ({Type}) from {Name} <{Email}> routed to back office.",
            submission.ReferenceNumber, submission.Type, submission.ContactName, submission.ContactEmail);

        _logger.LogInformation(
            "Acknowledgement email queued for {Email} — reference {Reference}.",
            submission.ContactEmail, submission.ReferenceNumber);

        return submission.ReferenceNumber;
    }

    private Task<PlatformSubmissionResult?> TrySubmitToPlatformAsync(QuoteSubmission submission, CancellationToken ct)
    {
        return submission.Type switch
        {
            SubmissionType.MedicalIndividual => SubmitMedicalIndividualAsync(submission, ct),

            SubmissionType.MedicalCorporate => _platformClient.SubmitMedicalCorporateAsync(
                submission.Details.GetValueOrDefault("CompanyName", string.Empty),
                submission.ContactPhone ?? string.Empty,
                submission.ContactEmail,
                submission.Details.GetValueOrDefault("IdNo", string.Empty),
                ct),

            SubmissionType.ProfessionalIndemnity when submission.Details.GetValueOrDefault("Stage") != "Proposal" =>
                _platformClient.SubmitProfessionalIndemnityAsync(
                    submission.ContactName,
                    submission.ContactPhone ?? string.Empty,
                    submission.ContactEmail,
                    submission.Details.GetValueOrDefault("Profession", string.Empty),
                    submission.Details.GetValueOrDefault("IdNo", string.Empty),
                    ct),

            SubmissionType.Travel => SubmitTravelAsync(submission, ct),

            SubmissionType.Domestic => _platformClient.SubmitDomesticAsync(
            BuildDomesticDetailsJson(submission),
            submission.Details.GetValueOrDefault("IdNo", string.Empty),
            submission.ContactEmail,
            ct),

            _ => Task.FromResult<PlatformSubmissionResult?>(null)
        };
    }

    private Task<PlatformSubmissionResult?> SubmitMedicalIndividualAsync(QuoteSubmission submission, CancellationToken ct)
    {
        var familyMembers = new List<(string Relationship, string FullName, DateTime DateOfBirth)>();
        if (submission.Details.TryGetValue("FamilyMembersJson", out var json) && !string.IsNullOrWhiteSpace(json))
        {
            var parsed = JsonSerializer.Deserialize<List<FamilyMemberJson>>(json);
            if (parsed != null)
            {
                familyMembers.AddRange(parsed.Select(m =>
                    (m.relationship, m.fullName, ParseIsoDate(m.dateOfBirth))));
            }
        }

        return _platformClient.SubmitMedicalIndividualAsync(
            submission.ContactName,
            ParseIsoDate(submission.Details.GetValueOrDefault("DateOfBirth", DateTime.UtcNow.ToString("yyyy-MM-dd"))),
            submission.Details.GetValueOrDefault("IdNo", string.Empty),
            submission.ContactEmail,
            submission.ContactPhone ?? string.Empty,
            familyMembers,
            ct);
    }

    private Task<PlatformSubmissionResult?> SubmitTravelAsync(QuoteSubmission submission, CancellationToken ct)
    {
        return _platformClient.SubmitTravelAsync(
            submission.ContactName,
            ParseIsoDate(submission.Details.GetValueOrDefault("DateOfBirth", DateTime.UtcNow.ToString("yyyy-MM-dd"))),
            string.IsNullOrWhiteSpace(submission.Details.GetValueOrDefault("KraPin")) ? null : submission.Details["KraPin"],
            submission.Details.GetValueOrDefault("Destination", string.Empty),
            ParseIsoDate(submission.Details.GetValueOrDefault("DepartureDate", DateTime.UtcNow.ToString("yyyy-MM-dd"))),
            ParseIsoDate(submission.Details.GetValueOrDefault("ReturnDate", DateTime.UtcNow.ToString("yyyy-MM-dd"))),
            bool.TryParse(submission.Details.GetValueOrDefault("TravellingWithFamily"), out var withFamily) && withFamily,
            submission.Details.GetValueOrDefault("TripType", "VACATION"),
            submission.Details.GetValueOrDefault("IdNo", string.Empty),
            submission.ContactEmail,
            ct);
    }

    private sealed class FamilyMemberJson
    {
        public string relationship { get; set; } = string.Empty;
        public string fullName { get; set; } = string.Empty;
        public string dateOfBirth { get; set; } = string.Empty;
    }

    private static DateTime ParseIsoDate(string value) =>
        DateTime.ParseExact(value, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);

    private static string BuildDomesticDetailsJson(QuoteSubmission submission)
    {
        var details = new
        {
            fullName = submission.ContactName,
            phone = submission.ContactPhone,
            idNo = submission.Details.GetValueOrDefault("IdNo"),
            email = submission.ContactEmail,
            propertyAddress = submission.Details.GetValueOrDefault("PropertyAddress"),
            propertyType = submission.Details.GetValueOrDefault("PropertyType"),
            estimatedValue = submission.Details.GetValueOrDefault("EstimatedValue")
        };
        return JsonSerializer.Serialize(details);
    }

    private static string GenerateReferenceNumber(SubmissionType type)
    {
        var prefix = type switch
        {
            SubmissionType.MedicalIndividual => "MED",
            SubmissionType.MedicalCorporate => "COR",
            SubmissionType.ProfessionalIndemnity => "PIN",
            SubmissionType.Travel => "TRV",
            SubmissionType.Domestic => "DOM",
            SubmissionType.Motor => "MOT",
            _ => "MSG"
        };

        var stamp = DateTimeOffset.UtcNow.ToString("yyMMdd");
        var suffix = Guid.NewGuid().ToString("N")[..5].ToUpperInvariant();
        return $"AMR-{prefix}-{stamp}-{suffix}";
    }

    private async Task PersistAsync(QuoteSubmission submission, CancellationToken ct)
    {
        var dataDir = Path.Combine(_env.ContentRootPath, "App_Data");
        Directory.CreateDirectory(dataDir);
        var filePath = Path.Combine(dataDir, "submissions.jsonl");

        var line = JsonSerializer.Serialize(submission) + Environment.NewLine;

        await _fileLock.WaitAsync(ct);
        try
        {
            await File.AppendAllTextAsync(filePath, line, ct);
        }
        finally
        {
            _fileLock.Release();
        }
    }
}