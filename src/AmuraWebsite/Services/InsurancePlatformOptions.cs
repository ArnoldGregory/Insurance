namespace AmuraWebsite.Services;

public sealed class InsurancePlatformOptions
{
    public const string SectionName = "InsurancePlatform";

    public string BaseUrl { get; set; } = string.Empty;
    public string WebsiteGuestApiKey { get; set; } = string.Empty;

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(BaseUrl) && !string.IsNullOrWhiteSpace(WebsiteGuestApiKey);
}
