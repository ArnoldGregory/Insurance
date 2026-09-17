namespace AmuraWebsite.Services;

/// <summary>
/// Task #4 — Backend quote submission & routing.
/// Single entry point every form (Contact + the 5 Get Quote forms) submits
/// through. Implementations are responsible for persisting the submission,
/// routing it to the back office, and triggering the client acknowledgement.
/// </summary>
public interface IQuoteSubmissionService
{
    Task<string> SubmitAsync(QuoteSubmission submission, CancellationToken ct = default);
}
