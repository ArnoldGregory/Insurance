using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IUnderwriterPolicyLevelNumberRepository
{
    /// <summary>Wraps usp_UnderwriterPolicyLevelNumber_Set - registers or corrects the one fixed policy_number for (underwriterId, policyLevelId).</summary>
    Task<StoredProcResult<long?>> SetAsync(long underwriterId, int policyLevelId, string policyNumber, long actorId);

    /// <summary>Wraps usp_UnderwriterPolicyLevelNumber_GetList - optionally filtered to one underwriter.</summary>
    Task<StoredProcResult<List<UnderwriterPolicyLevelNumber>>> GetListAsync(long? underwriterId);
}
