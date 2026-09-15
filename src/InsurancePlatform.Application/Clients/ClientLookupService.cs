using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Application.Clients;

public class ClientLookupService : IClientLookupService
{
    private const string NotFoundStatus = "NOT_FOUND";

    private readonly IClientRepository _clientRepository;
    private readonly ITaxpayerLookupClient _taxpayerLookupClient;
    private readonly ILoggerManager _logger;

    public ClientLookupService(IClientRepository clientRepository, ITaxpayerLookupClient taxpayerLookupClient, ILoggerManager logger)
    {
        _clientRepository = clientRepository;
        _taxpayerLookupClient = taxpayerLookupClient;
        _logger = logger;
    }

    public async Task<ClientLookupResult> ResolveOrEnrichAsync(string idNo)
    {
        var resolveResult = await _clientRepository.ResolveByIdNoAsync(idNo);
        var resolution = resolveResult.Data;

        // Already on file (either has a login, or was agent-created with
        // none) - return what usp_Client_ResolveByIdNo already knows and
        // stop there. No reason to spend a GovConnect call on someone
        // we've already got a record for.
        if (resolution is not null && resolution.MatchStatus != NotFoundStatus)
        {
            return new ClientLookupResult
            {
                MatchStatus = resolution.MatchStatus,
                ClientId = resolution.ClientId,
                FullName = resolution.FullName,
                Phone = resolution.Phone,
                Email = resolution.Email,
                EnrichedFromGovConnect = false
            };
        }

        // Nobody on file for this id_no - try GovConnect to save whoever's
        // filling this in (the person themselves, or an agent) from typing
        // three names and a KRA PIN by hand. Best-effort only: any failure
        // here (not found, gateway down, malformed response) just falls
        // through to a normal NOT_FOUND result with nothing filled in -
        // this must never block registration itself.
        TaxpayerLookupResult? taxpayer = null;
        try
        {
            taxpayer = await _taxpayerLookupClient.LookupAsync(idNo);
        }
        catch (Exception ex)
        {
            _logger.LogError($"GovConnect taxpayer lookup threw for id_no={idNo} - falling back to manual entry.", ex);
        }

        if (taxpayer is not null)
        {
            _logger.LogInfo($"GovConnect enriched id_no={idNo} with name/KRA PIN.");
        }

        return new ClientLookupResult
        {
            MatchStatus = NotFoundStatus,
            FullName = taxpayer?.FullName,
            KraPin = taxpayer?.Pin,
            EnrichedFromGovConnect = taxpayer is not null
        };
    }
}
