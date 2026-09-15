namespace InsurancePlatform.Api.Contracts.Clients;

/// <summary>Staff creating a client record with no login of their own.</summary>
// Matches usp_Client_Create's required fields exactly (IdNo/FullName/
// Phone/RegistrationChannel are the proc's own "these are required"
// check). RegisteredByUserId is NOT here - the server always fills that
// in from the caller's own JWT, never trusts a client-supplied value.
public class CreateClientRequest
{
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime? Dob { get; set; }
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? KraPin { get; set; }

    /// <summary>PORTAL, USSD, WHATSAPP or WEBSITE.</summary>
    // usp_Client_Create's own allowed set - narrower than the Clients
    // table's CHECK constraint; MOBILE is self-registration-only (see
    // /api/auth/register instead).
    public string RegistrationChannel { get; set; } = string.Empty;
}

/// <summary>Partial update - every field is optional.</summary>
// A field left out (null) keeps its current value in the database
// (usp_Client_Update COALESCEs), it does NOT get cleared. Despite being a
// PUT for REST-convention familiarity, this is PATCH semantics under the
// hood.
public class UpdateClientRequest
{
    public string? FullName { get; set; }
    public DateTime? Dob { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? KraPin { get; set; }
}
