using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

// Commission belongs to the Agent alone - one flat percentage that applies
// to every purchase they make, regardless of product or underwriter. No
// override-vs-default resolution here (that two-tier model was dropped) -
// this repository just sets/reads the agent's own rate history.
public interface IAgentCommissionRateRepository
{
    Task<StoredProcResult<long?>> SetAsync(long agentUserId, decimal ratePercent, DateTime? effectiveFrom, long setByUserId);

    Task<StoredProcResult<List<AgentCommissionRate>>> GetListByAgentAsync(long agentUserId);
}
