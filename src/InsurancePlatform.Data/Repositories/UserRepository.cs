using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public UserRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(string roleCode, string idNo, string fullName, string? email, string phone, string passwordHash, long actorId)
    {
        var userIdParam = new MySqlParameter("o_user_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_role_code", roleCode),
            new("p_id_no", idNo),
            new("p_full_name", fullName),
            new("p_email", (object?)email ?? DBNull.Value),
            new("p_phone", phone),
            new("p_password_hash", passwordHash),
            new("p_actor_type", "USER"),
            new("p_actor_id", actorId),
            userIdParam
        };

        var result = await _executor.ExecuteAsync("usp_User_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = userIdParam.Value is null or DBNull ? null : Convert.ToInt64(userIdParam.Value)
        };
    }

    public Task<StoredProcResult<User?>> GetByIdNoForLoginAsync(string idNo)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_id_no", idNo)
        };

        return _executor.ExecuteQuerySingleAsync("usp_User_GetByIdNoForLogin", parameters, MapRow);
    }

    public Task<StoredProcResult> UpdateStatusAsync(long userId, string status, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_user_id", userId),
            new("p_status", status),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_User_UpdateStatus", parameters);
    }

    public Task<StoredProcResult> UpdatePasswordAsync(long userId, string newPasswordHash, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_user_id", userId),
            new("p_new_password_hash", newPasswordHash),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_User_UpdatePassword", parameters);
    }

    public Task<StoredProcResult> RecordFailedLoginAsync(long userId)
    {
        var parameters = new List<MySqlParameter> { new("p_user_id", userId) };
        return _executor.ExecuteAsync("usp_User_RecordFailedLogin", parameters);
    }

    public Task<StoredProcResult> RecordSuccessfulLoginAsync(long userId)
    {
        var parameters = new List<MySqlParameter> { new("p_user_id", userId) };
        return _executor.ExecuteAsync("usp_User_RecordSuccessfulLogin", parameters);
    }

    public Task<StoredProcResult<List<StaffOption>>> GetListAsync(string? roleCode, long? createdByUserId, string? status, int pageNumber, int pageSize)
    {
        // Total count isn't needed by the one caller today (a dropdown wants
        // "every match", not a paginated grid) so, unlike QuoteRequestRepository.
        // GetListAsync, the o_total_count OUT param is bound but simply not
        // surfaced in the return type here - StaffOption list is enough.
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_role_code", (object?)roleCode ?? DBNull.Value),
            new("p_created_by_user_id", (object?)createdByUserId ?? DBNull.Value),
            new("p_status", (object?)status ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        return _executor.ExecuteQueryAsync("usp_User_GetList", parameters, MapStaffOptionRow);
    }

    private static StaffOption MapStaffOptionRow(MySqlDataReader reader)
    {
        return new StaffOption
        {
            UserId = reader.GetInt64("user_id"),
            RoleCode = reader.GetString("role_code"),
            RoleName = reader.GetString("role_name"),
            IdNo = reader.GetString("id_no"),
            FullName = reader.GetString("full_name"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            Phone = reader.GetString("phone"),
            Status = reader.GetString("status")
        };
    }

    private static User MapRow(MySqlDataReader reader)
    {
        return new User
        {
            UserId = reader.GetInt64("user_id"),
            RoleId = reader.GetInt64("role_id"),
            RoleCode = reader.GetString("role_code"),
            RoleName = reader.GetString("role_name"),
            FullName = reader.GetString("full_name"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            Phone = reader.GetString("phone"),
            PasswordHash = reader.GetString("password_hash"),
            Status = reader.GetString("status"),
            MustChangePassword = reader.GetBoolean("must_change_password")
        };
    }

    // usp_User_GetById does NOT return password_hash, so it needs its own
    // mapper (MapRow above would throw on reader.GetString("password_hash")).
    private static User MapByIdRow(MySqlDataReader reader)
    {
        return new User
        {
            UserId = reader.GetInt64("user_id"),
            RoleId = reader.GetInt64("role_id"),
            RoleCode = reader.GetString("role_code"),
            RoleName = reader.GetString("role_name"),
            FullName = reader.GetString("full_name"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            Phone = reader.GetString("phone"),
            PasswordHash = string.Empty,
            Status = reader.GetString("status"),
            MustChangePassword = reader.GetBoolean("must_change_password")
        };
    }

    public Task<StoredProcResult<User?>> GetByIdAsync(long userId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_user_id", userId)
        };

        return _executor.ExecuteQuerySingleAsync("usp_User_GetById", parameters, MapByIdRow);
    }

    public Task<StoredProcResult> DeleteAsync(long userId, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_user_id", userId),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_User_Delete", parameters);
    }

    public async Task<StoredProcResult<AgentCounts>> GetAgentCountsAsync()
    {
        var result = await _executor.ExecuteQuerySingleAsync(
            "usp_User_GetAgentCounts", new List<MySqlParameter>(), MapAgentCountsRow);

        return new StoredProcResult<AgentCounts>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new AgentCounts()
        };
    }

    private static AgentCounts MapAgentCountsRow(MySqlDataReader reader)
    {
        return new AgentCounts
        {
            TotalAgentCount = Convert.ToInt64(reader["total_agent_count"]),
            ActiveAgentCount = Convert.ToInt64(reader["active_agent_count"])
        };
    }
}
