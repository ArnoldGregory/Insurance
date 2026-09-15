using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IClientRepository
{
    /// <summary>
    /// Wraps usp_Client_SelfRegister - creates the Users row and the linked
    /// Clients row in one atomic call. Data is null only when ResultCode is
    /// NotFound-equivalent; check IsSuccess/IsDuplicate before reading it.
    /// </summary>
    Task<StoredProcResult<SelfRegistrationIds?>> SelfRegisterAsync(
        string idNo,
        string fullName,
        DateTime? dob,
        string? email,
        string phone,
        string? address,
        string? kraPin,
        string passwordHash,
        string registrationChannel);

    /// <summary>
    /// Wraps usp_Client_Create - a staff member (Agent/AgentAdmin/Support)
    /// creating a client record with NO login of their own (p_user_id is
    /// always NULL here; that only ever gets set by SelfRegisterAsync or,
    /// later, an attach-login flow). registrationChannel here uses the
    /// proc's own narrower set (PORTAL/USSD/WHATSAPP/WEBSITE) - MOBILE is
    /// self-registration-only, enforced by usp_Client_SelfRegister, not
    /// this proc.
    /// </summary>
    Task<StoredProcResult<long?>> CreateAsync(
        string idNo,
        string fullName,
        DateTime? dob,
        string? email,
        string phone,
        string? address,
        string? kraPin,
        long? registeredByUserId,
        string registrationChannel,
        string actorType,
        long actorId);

    /// <summary>Wraps usp_Client_GetById.</summary>
    Task<StoredProcResult<Client?>> GetByIdAsync(long clientId);

    /// <summary>
    /// Wraps usp_Client_GetList. registeredByUserId is the caller's own
    /// scoping filter, not a free-text search param - ClientsController
    /// decides what value to pass (an Agent's own user_id, or null for
    /// staff who see everyone), never trusts a client-supplied filter here.
    /// </summary>
    Task<StoredProcResult<ClientListPage>> GetListAsync(long? registeredByUserId, string? search, int pageNumber, int pageSize);

    /// <summary>
    /// Wraps usp_Client_Update. Every field except clientId/actorType/actorId
    /// is nullable and COALESCE'd against the existing row server-side - a
    /// null here means "leave this field alone," not "clear it."
    /// </summary>
    Task<StoredProcResult> UpdateAsync(
        long clientId,
        string? fullName,
        DateTime? dob,
        string? email,
        string? phone,
        string? address,
        string? kraPin,
        string actorType,
        long actorId);

    /// <summary>Wraps usp_Client_Delete - soft delete (isdeleted = 1).</summary>
    Task<StoredProcResult> DeleteAsync(long clientId, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_Client_ResolveByIdNo - the three-way identity check
    /// (NOT_FOUND/HAS_LOGIN/NO_LOGIN) used before registration (self- or
    /// agent-assisted) to check whether this id_no already has a record,
    /// instead of letting Create/SelfRegister fail with a duplicate error
    /// after the fact.
    /// </summary>
    Task<StoredProcResult<ClientResolution>> ResolveByIdNoAsync(string idNo);

    /// <summary>
    /// Wraps usp_Client_GetSummary - dashboard stat-card counts (total +
    /// new this month). Same registeredByUserId scoping convention as
    /// GetListAsync (null = platform-wide, an agent's own user_id for
    /// their own dashboard).
    /// </summary>
    Task<StoredProcResult<ClientDashboardSummary>> GetSummaryAsync(long? registeredByUserId);
}

/// <summary>
/// usp_Client_SelfRegister returns two new IDs (o_user_id, o_client_id) -
/// this just carries both back together, since StoredProcResult&lt;T&gt;
/// only has room for one Data value.
/// </summary>
public class SelfRegistrationIds
{
    public long UserId { get; init; }
    public long ClientId { get; init; }
}
