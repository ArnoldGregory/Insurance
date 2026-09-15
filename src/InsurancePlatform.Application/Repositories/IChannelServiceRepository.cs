using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IChannelServiceRepository
{
    /// <summary>Wraps usp_ChannelServiceAccount_GetByChannel.</summary>
    Task<StoredProcResult<ChannelServiceAccount?>> GetByChannelAsync(string channel);

    /// <summary>Wraps usp_ChannelServiceAccount_Create - apiKeyHash must already be hashed by the caller, never plaintext.</summary>
    Task<StoredProcResult<long?>> CreateAsync(string channel, string apiKeyHash, string? allowedIpRange, long actorId);

    /// <summary>Wraps usp_ChannelServiceAccount_GetList.</summary>
    Task<StoredProcResult<List<ChannelServiceAccountSummary>>> GetListAsync();

    /// <summary>Wraps usp_ChannelServiceAccount_SetStatus.</summary>
    Task<StoredProcResult> SetStatusAsync(long serviceAccountId, bool isActive, long actorId);

    /// <summary>Wraps usp_ChannelServiceAccount_RegenerateKey - newApiKeyHash must already be hashed by the caller.</summary>
    Task<StoredProcResult> RegenerateKeyAsync(long serviceAccountId, string newApiKeyHash, long actorId);
}
