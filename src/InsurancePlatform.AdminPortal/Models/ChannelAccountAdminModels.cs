using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>
/// Mirrors InsurancePlatform.Domain.Entities.ChannelServiceAccount -
/// the machine-to-machine channel-account row shown on the Channel Accounts
/// screen. Channel can be any string; the common one is WEBSITE_GUEST.
/// </summary>
public class ChannelAccountItem
{
    public long ServiceAccountId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string? AllowedIpRange { get; set; }
    public bool IsActive { get; set; }
    public string? RoleCode { get; set; }
}

/// <summary>Binding model for the Channel Accounts screen.</summary>
public class ChannelAccountsViewModel
{
    public List<ChannelAccountItem> Items { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Create-modal binding - POST /api/channel-accounts (CreateChannelAccountRequest).</summary>
public class CreateChannelAccountFormModel
{
    [Required(ErrorMessage = "Channel name is required.")]
    public string Channel { get; set; } = string.Empty;

    [Display(Name = "Allowed IP range")]
    public string? AllowedIpRange { get; set; }
}