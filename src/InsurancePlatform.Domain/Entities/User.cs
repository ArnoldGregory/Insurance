namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// Mirrors what usp_User_GetByIdNoForLogin's SELECT returns (see
/// Insurance_API_StoredProcs_Auth.sql): user_id, role_id, role_code,
/// role_name, full_name, email, phone, password_hash, status,
/// must_change_password - joined against Roles for role_code/role_name.
/// Note: the proc does NOT return id_no (the caller already has it - it's
/// what they logged in with), so this entity deliberately has no IdNo
/// property.
/// </summary>
public class User
{
    public long UserId { get; set; }
    public long RoleId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;

    /// <summary>Nullable - Users.email is NULL-able in the schema (phone is required, email isn't).</summary>
    public string? Email { get; set; }

    public string Phone { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;

    /// <summary>ACTIVE / INACTIVE / LOCKED - matches Users.status's CHECK constraint.</summary>
    public string Status { get; set; } = string.Empty;

    public bool MustChangePassword { get; set; }
}

/// <summary>
/// The deliberately-thin shape usp_User_GetList's SELECT maps to for
/// anything that just needs to LIST staff (e.g. the Quote Requests
/// "assign to a specific Support person" dropdown) - no PasswordHash,
/// MustChangePassword, or lockout fields, since those have no business
/// being serialized out over an HTTP API just to populate a picker.
/// </summary>
public class StaffOption
{
    public long UserId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

/// <summary>usp_User_GetAgentCounts's single-row shape - the dashboard's "Total Agents"/"Active Agents" widgets. "Active" means sold at least one policy in the last 30 days, not Users.Status.</summary>
public class AgentCounts
{
    public long TotalAgentCount { get; set; }
    public long ActiveAgentCount { get; set; }
}
