namespace InsurancePlatform.Application.Clients;

/// <summary>
/// The "check DB first, fall back to GovConnect" orchestration - lives
/// here rather than inside ClientRepository or RegistrationService because
/// it combines two different sources (usp_Client_ResolveByIdNo via
/// IClientRepository, and the GovConnect gateway via ITaxpayerLookupClient)
/// and is meant to be reusable by both self-registration and
/// agent-assisted client creation, not owned by either one.
/// </summary>
public interface IClientLookupService
{
    Task<ClientLookupResult> ResolveOrEnrichAsync(string idNo);
}

/// <summary>
/// Always exactly one of two shapes: MatchStatus is HAS_LOGIN/NO_LOGIN with
/// ClientId/FullName/Phone/Email populated from the existing record (KraPin
/// is never populated here - usp_Client_ResolveByIdNo doesn't select it,
/// and if they're already on file there's no need to enrich anything); or
/// MatchStatus is NOT_FOUND with FullName/KraPin populated from GovConnect
/// IF EnrichedFromGovConnect is true, otherwise both null - meaning nobody
/// has this id_no on file AND GovConnect had nothing either, so whichever
/// UI called this just shows a normal blank form for manual entry.
/// </summary>
public class ClientLookupResult
{
    public string MatchStatus { get; set; } = string.Empty;
    public long? ClientId { get; set; }
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? KraPin { get; set; }
    public bool EnrichedFromGovConnect { get; set; }
}
