namespace InsurancePlatform.Domain.Entities;

/// <summary>Full underwriter record - usp_Underwriter_GetById's row shape.</summary>
public class Underwriter
{
    public long UnderwriterId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsActive { get; set; }
    public string? DmvicCode { get; set; }

    /// <summary>"FIXED" (reuses one policy_number per policy_level - see UnderwriterPolicyLevelNumber) or "CHANGE" (auto-generated per purchase, the original behavior).</summary>
    public string PolicyType { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

/// <summary>List-row shape - usp_Underwriter_GetList doesn't select dmvic_code.</summary>
public class UnderwriterSummary
{
    public long UnderwriterId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsActive { get; set; }

    /// <summary>"FIXED" or "CHANGE" - see Underwriter.PolicyType.</summary>
    public string PolicyType { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}
