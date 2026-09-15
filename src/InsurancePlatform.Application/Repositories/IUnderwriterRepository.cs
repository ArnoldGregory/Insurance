using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IUnderwriterRepository
{
    Task<StoredProcResult<long?>> CreateAsync(string name, string code, string? contactEmail, string? contactPhone, long actorId);

    Task<StoredProcResult<Underwriter?>> GetByIdAsync(long underwriterId);

    Task<StoredProcResult<List<UnderwriterSummary>>> GetListAsync(bool? activeOnly);

    Task<StoredProcResult> UpdateAsync(long underwriterId, string? name, string? contactEmail, string? contactPhone, long actorId);

    Task<StoredProcResult> SetActiveStatusAsync(long underwriterId, bool isActive, long actorId);

    /// <summary>Wraps usp_Underwriter_SetPolicyType - "FIXED" or "CHANGE" (see Underwriters.policy_type's schema comment).</summary>
    Task<StoredProcResult> SetPolicyTypeAsync(long underwriterId, string policyType, long actorId);
}
