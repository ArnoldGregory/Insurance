using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class ClientRepository : IClientRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public ClientRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<SelfRegistrationIds?>> SelfRegisterAsync(
        string idNo,
        string fullName,
        DateTime? dob,
        string? email,
        string phone,
        string? address,
        string? kraPin,
        string passwordHash,
        string registrationChannel)
    {
        // usp_Client_SelfRegister declares two proc-specific OUT params
        // (o_user_id, o_client_id) beyond the standard envelope - both have
        // to be built here and read back after the call, same pattern as
        // OtpRepository's o_otp_id.
        var userIdParam = new MySqlParameter("o_user_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var clientIdParam = new MySqlParameter("o_client_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_id_no", idNo),
            new("p_full_name", fullName),
            new("p_dob", (object?)dob ?? DBNull.Value),
            new("p_email", (object?)email ?? DBNull.Value),
            new("p_phone", phone),
            new("p_address", (object?)address ?? DBNull.Value),
            new("p_kra_pin", (object?)kraPin ?? DBNull.Value),
            new("p_password_hash", passwordHash),
            new("p_registration_channel", registrationChannel),
            userIdParam,
            clientIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Client_SelfRegister", parameters);

        SelfRegistrationIds? ids = null;
        if (result.IsSuccess)
        {
            ids = new SelfRegistrationIds
            {
                UserId = Convert.ToInt64(userIdParam.Value),
                ClientId = Convert.ToInt64(clientIdParam.Value)
            };
        }

        return new StoredProcResult<SelfRegistrationIds?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = ids
        };
    }

    public async Task<StoredProcResult<long?>> CreateAsync(
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
        long actorId)
    {
        var clientIdParam = new MySqlParameter("o_client_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_id_no", idNo),
            new("p_full_name", fullName),
            new("p_dob", (object?)dob ?? DBNull.Value),
            new("p_email", (object?)email ?? DBNull.Value),
            new("p_phone", phone),
            new("p_address", (object?)address ?? DBNull.Value),
            new("p_kra_pin", (object?)kraPin ?? DBNull.Value),
            // p_user_id: always NULL from this proc call - staff-created
            // clients get no login until a separate attach-login flow runs.
            new("p_user_id", DBNull.Value),
            new("p_registered_by_user_id", (object?)registeredByUserId ?? DBNull.Value),
            new("p_registration_channel", registrationChannel),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            clientIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Client_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = clientIdParam.Value is null or DBNull ? null : Convert.ToInt64(clientIdParam.Value)
        };
    }

    public Task<StoredProcResult<Client?>> GetByIdAsync(long clientId)
    {
        var parameters = new List<MySqlParameter> { new("p_client_id", clientId) };
        return _executor.ExecuteQuerySingleAsync("usp_Client_GetById", parameters, MapRow);
    }

    public async Task<StoredProcResult<ClientListPage>> GetListAsync(long? registeredByUserId, string? search, int pageNumber, int pageSize)
    {
        // o_total_count is proc-specific, declared after the envelope in
        // usp_Client_GetList's signature - built and added here the same
        // way SelfRegisterAsync builds o_user_id/o_client_id.
        // MySqlStoredProcedureExecutor.EnsureEnvelopeParameters inserts
        // o_result_code/o_result_message right before this one, landing
        // everything in the same order the real proc declares them.
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_registered_by_user_id", (object?)registeredByUserId ?? DBNull.Value),
            new("p_search", (object?)search ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        var result = await _executor.ExecuteQueryAsync("usp_Client_GetList", parameters, MapSummaryRow);

        var page = new ClientListPage
        {
            TotalCount = totalCountParam.Value is null or DBNull ? 0 : Convert.ToInt64(totalCountParam.Value),
            Items = result.Data ?? new List<ClientSummary>()
        };

        return new StoredProcResult<ClientListPage>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = page
        };
    }

    public Task<StoredProcResult> UpdateAsync(
        long clientId,
        string? fullName,
        DateTime? dob,
        string? email,
        string? phone,
        string? address,
        string? kraPin,
        string actorType,
        long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", clientId),
            new("p_full_name", (object?)fullName ?? DBNull.Value),
            new("p_dob", (object?)dob ?? DBNull.Value),
            new("p_email", (object?)email ?? DBNull.Value),
            new("p_phone", (object?)phone ?? DBNull.Value),
            new("p_address", (object?)address ?? DBNull.Value),
            new("p_kra_pin", (object?)kraPin ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Client_Update", parameters);
    }

    public Task<StoredProcResult> DeleteAsync(long clientId, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", clientId),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Client_Delete", parameters);
    }

    private static Client MapRow(MySqlDataReader reader)
    {
        return new Client
        {
            ClientId = reader.GetInt64("client_id"),
            IdNo = reader.GetString("id_no"),
            FullName = reader.GetString("full_name"),
            Dob = reader.IsDBNull(reader.GetOrdinal("dob")) ? null : reader.GetDateTime("dob"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            Phone = reader.GetString("phone"),
            Address = reader.IsDBNull(reader.GetOrdinal("address")) ? null : reader.GetString("address"),
            KraPin = reader.IsDBNull(reader.GetOrdinal("kra_pin")) ? null : reader.GetString("kra_pin"),
            UserId = reader.IsDBNull(reader.GetOrdinal("user_id")) ? null : reader.GetInt64("user_id"),
            RegisteredByUserId = reader.IsDBNull(reader.GetOrdinal("registered_by_user_id")) ? null : reader.GetInt64("registered_by_user_id"),
            RegistrationChannel = reader.GetString("registration_channel"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    public async Task<StoredProcResult<ClientResolution>> ResolveByIdNoAsync(string idNo)
    {
        var clientIdParam = new MySqlParameter("o_client_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var matchStatusParam = new MySqlParameter("o_match_status", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_id_no", idNo),
            clientIdParam,
            matchStatusParam
        };

        // usp_Client_ResolveByIdNo's SELECT only runs for HAS_LOGIN/NO_LOGIN
        // (it LEAVEs before the SELECT for NOT_FOUND) - ExecuteQuerySingleAsync
        // already handles "zero rows" gracefully (Data stays null), so the
        // NOT_FOUND case just falls through to the empty-ClientResolution
        // fallback below.
        var queryResult = await _executor.ExecuteQuerySingleAsync("usp_Client_ResolveByIdNo", parameters, MapResolutionRow);

        var resolution = queryResult.Data ?? new ClientResolution();
        resolution.MatchStatus = matchStatusParam.Value is null or DBNull ? "NOT_FOUND" : matchStatusParam.Value.ToString()!;
        resolution.ClientId = clientIdParam.Value is null or DBNull ? null : Convert.ToInt64(clientIdParam.Value);

        return new StoredProcResult<ClientResolution>
        {
            ResultCode = queryResult.ResultCode,
            ResultMessage = queryResult.ResultMessage,
            Data = resolution
        };
    }

    private static ClientResolution MapResolutionRow(MySqlDataReader reader)
    {
        return new ClientResolution
        {
            ClientId = reader.GetInt64("client_id"),
            FullName = reader.GetString("full_name"),
            Phone = reader.GetString("phone"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email")
        };
    }

    private static ClientSummary MapSummaryRow(MySqlDataReader reader)
    {
        return new ClientSummary
        {
            ClientId = reader.GetInt64("client_id"),
            IdNo = reader.GetString("id_no"),
            FullName = reader.GetString("full_name"),
            Phone = reader.GetString("phone"),
            Email = reader.IsDBNull(reader.GetOrdinal("email")) ? null : reader.GetString("email"),
            UserId = reader.IsDBNull(reader.GetOrdinal("user_id")) ? null : reader.GetInt64("user_id"),
            RegisteredByUserId = reader.IsDBNull(reader.GetOrdinal("registered_by_user_id")) ? null : reader.GetInt64("registered_by_user_id"),
            RegistrationChannel = reader.GetString("registration_channel"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    public async Task<StoredProcResult<ClientDashboardSummary>> GetSummaryAsync(long? registeredByUserId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_registered_by_user_id", (object?)registeredByUserId ?? DBNull.Value)
        };

        var result = await _executor.ExecuteQuerySingleAsync("usp_Client_GetSummary", parameters, MapDashboardSummaryRow);

        return new StoredProcResult<ClientDashboardSummary>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = result.Data ?? new ClientDashboardSummary()
        };
    }

    private static ClientDashboardSummary MapDashboardSummaryRow(MySqlDataReader reader)
    {
        return new ClientDashboardSummary
        {
            TotalCount = Convert.ToInt64(reader["total_count"]),
            NewThisMonthCount = Convert.ToInt64(reader["new_this_month_count"])
        };
    }
}
