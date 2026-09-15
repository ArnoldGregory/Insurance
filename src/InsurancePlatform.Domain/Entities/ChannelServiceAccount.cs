namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One row from usp_ChannelServiceAccount_GetByChannel - a machine
/// credential for a whole channel gateway (USSD, WhatsApp), not an
/// individual person. AllowedIpRange exists in the schema but isn't
/// enforced anywhere yet - a deliberately deferred piece, not an oversight.
/// </summary>
public class ChannelServiceAccount
{
    public long ServiceAccountId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string ApiKeyHash { get; set; } = string.Empty;
    public string? AllowedIpRange { get; set; }
    public long RoleId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
}

/// <summary>usp_ChannelServiceAccount_GetList's row shape - the SuperAdmin-facing admin listing. Deliberately no ApiKeyHash field, same reasoning Users/Clients listings never return password_hash.</summary>
public class ChannelServiceAccountSummary
{
    public long ServiceAccountId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string? AllowedIpRange { get; set; }
    public bool IsActive { get; set; }
    public string RoleCode { get; set; } = string.Empty;
}

/// <summary>usp_ChannelServiceAccount_Create's proc-specific OUT param, plus the plaintext ApiKey the controller generates before hashing - the ONLY place/time it's ever available in plaintext. Never persisted, never logged, never retrievable again after this response.</summary>
public class ChannelAccountCreateResult
{
    public long ServiceAccountId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
}
