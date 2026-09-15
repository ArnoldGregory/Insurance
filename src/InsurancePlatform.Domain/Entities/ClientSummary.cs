namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One row from usp_Client_GetList - the lighter-weight shape used for
/// listing/searching, as opposed to Client (usp_Client_GetById's full row).
/// </summary>
public class ClientSummary
{
    public long ClientId { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public long? UserId { get; set; }
    public long? RegisteredByUserId { get; set; }
    public string RegistrationChannel { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

/// <summary>
/// usp_Client_GetList returns a total row count (for pagination) alongside
/// the page of rows itself - this carries both back together, since
/// StoredProcResult&lt;T&gt; only has room for one Data value (same reason
/// SelfRegistrationIds exists for usp_Client_SelfRegister's two new IDs).
/// </summary>
public class ClientListPage
{
    public long TotalCount { get; set; }
    public List<ClientSummary> Items { get; set; } = new();
}

/// <summary>usp_Client_GetSummary's single-row shape - dashboard stat-card counts. Named "DashboardSummary"
/// (not "Summary") because ClientSummary above is already taken by usp_Client_GetList's row shape.</summary>
public class ClientDashboardSummary
{
    public long TotalCount { get; set; }
    public long NewThisMonthCount { get; set; }
}
