using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.User.StaffOption - one staff (AA/AG/SP) row.</summary>
public class StaffUserItem
{
    public long UserId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;

    public string StatusBadgeCss => Status switch
    {
        "ACTIVE" => "label-success",
        "SUSPENDED" => "label-danger",
        _ => "label-warning"
    };
}

/// <summary>Admin (SA) Agent Admins screen - create AgentAdmin + list existing AAs.</summary>
public class AgentAdminsViewModel
{
    public List<StaffUserItem> Items { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Admin (AA) Agents screen - create Agent + list existing AGs.</summary>
public class AgentsViewModel
{
    public List<StaffUserItem> Items { get; set; } = new();
    public long ActiveCount { get; set; }
    public long TotalCount { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Admin (SA+AA) Support Agents screen - create Support_Agent + list existing SPs, with silent (soft) delete.</summary>
public class SupportAgentsViewModel
{
    public List<StaffUserItem> Items { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Create-agent-modal binding - POST /api/staff/agent-admins (CreateAgentAdminRequest) or POST /api/staff/agents (CreateAgentRequest).</summary>
public class CreateStaffFormModel
{
    [Required(ErrorMessage = "ID number is required.")]
    [Display(Name = "ID Number")]
    public string IdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Full name is required.")]
    [Display(Name = "Full Name")]
    public string FullName { get; set; } = string.Empty;

    [Display(Name = "Email")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Phone is required.")]
    [Display(Name = "Phone")]
    public string Phone { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [DataType(DataType.Password)]
    public string Password { get; set; } = string.Empty;
}