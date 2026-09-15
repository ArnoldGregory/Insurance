namespace InsurancePlatform.Api.Contracts.ChannelAccounts;

// Channel is free text now (the old chk_channel_accounts_channel CHECK
// constraint limiting it to USSD/WHATSAPP/WEBSITE_GUEST was dropped - see
// Insurance_API_Schema.sql) - ChannelAccountsController still validates
// its shape (uppercase, alphanumeric/underscore, max 20 chars) so this
// doesn't become a free-for-all typo trap.
public class CreateChannelAccountRequest
{
    public string Channel { get; set; } = string.Empty;
    public string? AllowedIpRange { get; set; }
}

public class SetChannelAccountStatusRequest
{
    public bool IsActive { get; set; }
}
