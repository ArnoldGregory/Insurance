namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Underwriter - one row in the Underwriters catalog.</summary>
public class UnderwriterItem
{
    public long UnderwriterId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsActive { get; set; }
    public string? DmvicCode { get; set; }
    public string? PolicyType { get; set; }
    public DateTime CreatedOn { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.UnderwriterPolicyLevelNumber - one policy-number allocation (FIXED vs CHANGE policy numbering).</summary>
public class UnderwriterPolicyLevelNumberItem
{
    public long Id { get; set; }
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public string? PolicyType { get; set; }
    public long PolicyLevelId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

/// <summary>Full-page binding model for the Underwriters screen (list + policy-number rows + create/edit modal).</summary>
public class UnderwritersIndexViewModel
{
    public List<UnderwriterItem> Items { get; set; } = new();
    public List<UnderwriterPolicyLevelNumberItem> PolicyLevelNumbers { get; set; } = new();

    public bool ShowInactive { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}

/// <summary>Create/edit modal binding model. Null UnderwriterId = create (POST /api/underwriters), present = edit (PUT /api/underwriters/{id}, which never changes Code).</summary>
public class UnderwriterFormModel
{
    public long? UnderwriterId { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
}

/// <summary>Modal that allocates a policy-level number to an underwriter (PUT /api/underwriters/{id}/policy-level-numbers).</summary>
public class PolicyLevelNumberFormModel
{
    public long UnderwriterId { get; set; }
    public long PolicyLevelId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
}

/// <summary>Selector options for the policy-level picker - mirrors InsurancePlatform.Domain.Entities.PolicyLevel.</summary>
public class PolicyLevelOption
{
    public long PolicyLevelId { get; set; }
    public string Name { get; set; } = string.Empty;
}