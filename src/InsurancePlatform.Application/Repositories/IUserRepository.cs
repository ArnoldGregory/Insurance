using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IUserRepository
{
    /// <summary>
    /// Wraps usp_User_Create - creates a staff/portal-login account
    /// (Super_Admin -> Agent_admin, Agent_admin -> Agent/Support_Agent).
    /// Account starts ACTIVE with must_change_password=1, no OTP round-trip
    /// (unlike client self-registration) since the caller creating this
    /// account is already an authenticated, authorized staff member. Which
    /// roleCode a given caller is allowed to create is a StaffController
    /// decision, not this repository's or the proc's.
    /// </summary>
    Task<StoredProcResult<long?>> CreateAsync(string roleCode, string idNo, string fullName, string? email, string phone, string passwordHash, long actorId);

    Task<StoredProcResult<User?>> GetByIdNoForLoginAsync(string idNo);

    /// <summary>
    /// Wraps usp_User_UpdateStatus. Used right now to flip a freshly
    /// self-registered account from INACTIVE to ACTIVE once its REGISTER-
    /// purpose OTP is confirmed - actorType/actorId are "USER"/the same
    /// user_id, since this is a self-action, not staff acting on someone
    /// else's account.
    /// </summary>
    Task<StoredProcResult> UpdateStatusAsync(long userId, string status, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_User_UpdatePassword - the final step of password reset
    /// (after usp_Otp_Verify, purpose='RESET_PASSWORD', has already
    /// succeeded) and also reusable for a logged-in user changing their
    /// own password later.
    /// </summary>
    Task<StoredProcResult> UpdatePasswordAsync(long userId, string newPasswordHash, string actorType, long actorId);

    /// <summary>
    /// Wraps usp_User_RecordFailedLogin - called after a wrong-password
    /// attempt. Locks the account (status=LOCKED, 15-minute cooldown) once
    /// failed_login_attempts hits 5; see usp_User_GetByIdNoForLogin for the
    /// matching auto-unlock check on the next login attempt.
    /// </summary>
    Task<StoredProcResult> RecordFailedLoginAsync(long userId);

    /// <summary>
    /// Wraps usp_User_RecordSuccessfulLogin - called right after a correct
    /// password check. Clears the failed-attempt counter/lock state and
    /// stamps last_login_on.
    /// </summary>
    Task<StoredProcResult> RecordSuccessfulLoginAsync(long userId);

    /// <summary>
    /// Wraps usp_User_GetList - used right now for the Quote Requests
    /// "assign to a specific Support person" dropdown (roleCode "SP",
    /// status "ACTIVE"), kept general enough (matches the proc's own
    /// parameter list) to reuse for any other staff-picker later.
    /// </summary>
    Task<StoredProcResult<List<StaffOption>>> GetListAsync(string? roleCode, long? createdByUserId, string? status, int pageNumber, int pageSize);

    /// <summary>Wraps usp_User_GetAgentCounts - the dashboard's "Total Agents"/"Active Agents" widgets.</summary>
    Task<StoredProcResult<AgentCounts>> GetAgentCountsAsync();

    /// <summary>
    /// Wraps usp_User_GetById - profile fetch by user_id (no password hash
    /// returned, unlike usp_User_GetByIdNoForLogin). Used by the Support
    /// Agents silent-delete flow to confirm the target account's role before
    /// letting an SA/AA soft-delete it.
    /// </summary>
    Task<StoredProcResult<User?>> GetByIdAsync(long userId);

    /// <summary>
    /// Wraps usp_User_Delete - soft delete only (isdeleted=1 + status
    /// INACTIVE, audit 'DELETE' row). The account stops appearing in every
    /// isdeleted=0 query and can no longer log in, but the row is kept.
    /// </summary>
    Task<StoredProcResult> DeleteAsync(long userId, string actorType, long actorId);
}
