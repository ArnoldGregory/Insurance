namespace InsurancePlatform.Api.Contracts.Underwriters;

public class CreateUnderwriterRequest
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
}

/// <summary>Partial update - a null field keeps its current value.</summary>
// Code is deliberately not editable here - usp_Underwriter_Update doesn't
// accept it, since changing an underwriter's code after TpoPriceMapping/
// CommissionRates rows already reference it by underwriter_id (not code)
// would be a cosmetic-only change with no real use case yet.
public class UpdateUnderwriterRequest
{
    public string? Name { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
}

public class SetUnderwriterActiveStatusRequest
{
    public bool IsActive { get; set; }
}

/// <summary>"FIXED" or "CHANGE" - see Underwriter.PolicyType's doc comment.</summary>
public class SetUnderwriterPolicyTypeRequest
{
    public string PolicyType { get; set; } = string.Empty;
}

/// <summary>Registers or corrects the one fixed, reused policy_number this underwriter stamps on every certificate at PolicyLevelId. UnderwriterId comes from the route.</summary>
public class SetUnderwriterPolicyLevelNumberRequest
{
    public int PolicyLevelId { get; set; }
    public string PolicyNumber { get; set; } = string.Empty;
}
