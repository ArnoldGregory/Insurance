namespace InsurancePlatform.Api.Contracts.Staff;

/// <summary>Super_Admin creating an Agent_admin account.</summary>
// No RoleCode field here - this endpoint only ever creates AA, so there's
// nothing for the caller to choose. Password is a temporary one the new
// account must change on first login (Users.must_change_password=1 is set
// unconditionally by usp_User_Create).
public class CreateAgentAdminRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>Agent_admin creating an Agent or Support_Agent account.</summary>
// RoleCode is caller-supplied here (unlike CreateAgentAdminRequest) because
// CREATE_AGENT is the one permission that covers both AG and SP per the
// RolePermissions seed - StaffController.CreateAgent rejects anything
// other than "AG"/"SP" so an AgentAdmin can't use this to mint another
// AgentAdmin or SuperAdmin.
public class CreateAgentRequest
{
    /// <summary>AG (Agent) or SP (Support_Agent).</summary>
    public string RoleCode { get; set; } = string.Empty;
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>Super_Admin or Agent_admin creating a Support_Agent account.</summary>
// No RoleCode field - this endpoint only ever creates SP, so there's
// nothing for the caller to choose. Gated by ROLES (SA+AA), not by the
// CREATE_AGENT permission, because the RolePermissions seed only grants
// CREATE_AGENT to AgentAdmin - yet the Support Agents screen is meant to
// be usable by both Super_Admin and Agent_admin.
public class CreateSupportAgentRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class CreateStaffData
{
    public long UserId { get; set; }
}
