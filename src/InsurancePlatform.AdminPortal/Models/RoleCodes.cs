namespace InsurancePlatform.AdminPortal.Models;

/// <summary>
/// Mirrors InsurancePlatform.Domain.Common.RoleCodes - duplicated here for
/// the same reason ApiModels.cs's ApiResponse&lt;T&gt;/MenuTreeItem are
/// duplicated instead of referenced: this project has zero ProjectReferences
/// to any other InsurancePlatform.* project (see the .csproj's top comment),
/// so every controller's [Authorize(Roles = ...)] attribute needs these
/// values as plain local constants. CL (Client) and CS (ChannelService)
/// are included for completeness but never actually appear in an
/// [Authorize(Roles=...)] here - neither role signs into this staff-only
/// portal (Client uses bima-dline-web; ChannelService is machine-to-machine).
/// </summary>
public static class RoleCodes
{
    public const string SuperAdmin = "SA";
    public const string AgentAdmin = "AA";
    public const string Agent = "AG";
    public const string SupportAgent = "SP";
    public const string Client = "CL";
    public const string ChannelService = "CS";

    /// <summary>SA, AA, SP - matches QuoteRequestsController.BackofficeRoles on the API side.</summary>
    public const string QuoteBackoffice = "SA,AA,SP";

    /// <summary>AA, SP - matches AgentCommissionsController.BackofficeRoles on the API side.</summary>
    public const string CommissionsBackoffice = "AA,SP";

    /// <summary>SA, AA, AG, SP - every staff role that signs into this portal. Matches ClientsController.GetList/PurchasesController's broadest [Authorize(Roles=...)] on the API side.</summary>
    public const string AllStaff = "SA,AA,AG,SP";

    /// <summary>AA, AG, SP - holders of CREATE_CLIENT (not SA - see RolePermissions in Insurance_API_Schema.sql).</summary>
    public const string ClientCreators = "AA,AG,SP";

    /// <summary>AA, SP - holders of EDIT_CLIENT (not AG, not SA).</summary>
    public const string ClientEditors = "AA,SP";

    /// <summary>AA, AG, SP - holders of PURCHASE_ON_BEHALF (not SA - PurchasesController.Create Forbid()s a staff caller who lacks this permission). Gates the whole purchase wizard.</summary>
    public const string PurchaseCreators = "AA,AG,SP";
}
