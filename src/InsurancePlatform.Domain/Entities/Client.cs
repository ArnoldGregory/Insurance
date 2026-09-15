namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One full Clients row, as returned by usp_Client_GetById. Deliberately a
/// separate type from ClientSummary (usp_Client_GetList's row shape) rather
/// than one type with some properties left unset - GetList doesn't select
/// Dob/Address/KraPin at all, so a shared type would leave those silently
/// null on every list row with no way to tell "not selected" apart from
/// "genuinely null in the database."
/// </summary>
public class Client
{
    public long ClientId { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime? Dob { get; set; }
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? KraPin { get; set; }

    /// <summary>
    /// Null for clients created by an agent/support/admin with no login of
    /// their own yet. Set for self-registered clients, or ones an agent has
    /// since attached a login to. This is also what ownership checks in
    /// ClientsController/VehiclesController compare a Client-role caller's
    /// own user_id against.
    /// </summary>
    public long? UserId { get; set; }

    public long? RegisteredByUserId { get; set; }
    public string RegistrationChannel { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}
