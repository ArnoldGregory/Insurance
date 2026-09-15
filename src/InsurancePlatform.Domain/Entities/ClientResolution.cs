namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// Result of usp_Client_ResolveByIdNo - the three-way identity check.
/// FullName/Phone/Email are only populated when MatchStatus isn't
/// NOT_FOUND (the proc's own SELECT only runs in that case); a fresh
/// ClientResolution with just MatchStatus="NOT_FOUND" set and everything
/// else null represents "nobody on file for this id_no".
/// </summary>
public class ClientResolution
{
    /// <summary>NOT_FOUND / HAS_LOGIN / NO_LOGIN.</summary>
    public string MatchStatus { get; set; } = string.Empty;
    public long? ClientId { get; set; }
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
}
