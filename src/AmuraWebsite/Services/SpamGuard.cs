using System.Text;

namespace AmuraWebsite.Services;

/// <summary>
/// Lightweight, no-account-needed spam protection for public forms.
/// Two checks, both defeat the vast majority of basic bots without
/// needing a CAPTCHA provider or API key:
///
///   1. Honeypot — a field real users never see or fill in. Bots that
///      auto-fill every input on a page fill it too.
///   2. Time trap — a token embedded on page load; if the form comes
///      back faster than a human could plausibly fill it out, it's
///      treated as automated.
///
/// This is a reasonable deterrent, not a guarantee — if spam becomes a
/// real problem later, swap in reCAPTCHA/hCaptcha without touching the
/// forms' other logic.
/// </summary>
public static class SpamGuard
{
    private static readonly TimeSpan MinFillTime = TimeSpan.FromSeconds(2);

    public static string GenerateFormToken() =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(DateTimeOffset.UtcNow.ToString("O")));

    /// <summary>
    /// Returns true if the submission looks automated and should be
    /// silently dropped (show success, don't persist, don't route).
    /// </summary>
    public static bool LooksLikeSpam(string? honeypotValue, string? formToken)
    {
        if (!string.IsNullOrWhiteSpace(honeypotValue))
        {
            return true;
        }

        if (string.IsNullOrWhiteSpace(formToken))
        {
            return true;
        }

        try
        {
            var renderedAt = DateTimeOffset.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(formToken)));
            return DateTimeOffset.UtcNow - renderedAt < MinFillTime;
        }
        catch
        {
            return true;
        }
    }
}
