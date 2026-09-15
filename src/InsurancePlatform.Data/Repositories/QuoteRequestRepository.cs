using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class QuoteRequestRepository : IQuoteRequestRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public QuoteRequestRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<QuoteRequestCreateResult?>> CreateMedicalIndividualAsync(
        long? clientId, long? requestedByUserId,
        string idNo, string firstName, string lastName, string? otherNames, string email, string mobileNumber,
        decimal inpatientLimit, bool hasOutpatient, decimal? outpatientLimit,
        bool hasDental, decimal? dentalLimit, bool hasMaternity,
        string? familyMembersJson, string actorType, long actorId)
    {
        var quoteRequestIdParam = new MySqlParameter("o_quote_request_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var refNoParam = new MySqlParameter("o_ref_no", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_requested_by_user_id", (object?)requestedByUserId ?? DBNull.Value),
            new("p_id_no", idNo),
            new("p_first_name", firstName),
            new("p_last_name", lastName),
            new("p_other_names", (object?)otherNames ?? DBNull.Value),
            new("p_email", email),
            new("p_mobile_number", mobileNumber),
            new("p_inpatient_limit", inpatientLimit),
            new("p_has_outpatient", hasOutpatient),
            new("p_outpatient_limit", (object?)outpatientLimit ?? DBNull.Value),
            new("p_has_dental", hasDental),
            new("p_dental_limit", (object?)dentalLimit ?? DBNull.Value),
            new("p_has_maternity", hasMaternity),
            new("p_family_members_json", (object?)familyMembersJson ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            quoteRequestIdParam,
            refNoParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteRequestMedicalIndividual_Create", parameters);
        return ToCreateResult(result, quoteRequestIdParam, refNoParam);
    }

    public async Task<StoredProcResult<QuoteRequestCreateResult?>> CreateMedicalCorporateAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string companyName, string phone,
        string email, string actorType, long actorId)
    {
        var quoteRequestIdParam = new MySqlParameter("o_quote_request_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var refNoParam = new MySqlParameter("o_ref_no", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_requested_by_user_id", (object?)requestedByUserId ?? DBNull.Value),
            new("p_channel", channel),
            new("p_id_no", idNo),
            new("p_company_name", companyName),
            new("p_phone", phone),
            new("p_email", email),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            quoteRequestIdParam,
            refNoParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteRequestMedicalCorporate_Create", parameters);
        return ToCreateResult(result, quoteRequestIdParam, refNoParam);
    }

    public async Task<StoredProcResult<QuoteRequestCreateResult?>> CreateProfessionalIndemnityAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string clientOrCompanyName, string phone,
        string email, string profession, string actorType, long actorId)
    {
        var quoteRequestIdParam = new MySqlParameter("o_quote_request_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var refNoParam = new MySqlParameter("o_ref_no", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_requested_by_user_id", (object?)requestedByUserId ?? DBNull.Value),
            new("p_channel", channel),
            new("p_id_no", idNo),
            new("p_client_or_company_name", clientOrCompanyName),
            new("p_phone", phone),
            new("p_email", email),
            new("p_profession", profession),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            quoteRequestIdParam,
            refNoParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteRequestProfessionalIndemnity_Create", parameters);
        return ToCreateResult(result, quoteRequestIdParam, refNoParam);
    }

    public async Task<StoredProcResult<QuoteRequestCreateResult?>> CreateTravelAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string email, string clientName, DateTime dob,
        string? kraPin, string destination, DateTime travelDateFrom, DateTime travelDateTo,
        bool? travellingWithFamily, string tripType, string actorType, long actorId)
    {
        var quoteRequestIdParam = new MySqlParameter("o_quote_request_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var refNoParam = new MySqlParameter("o_ref_no", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_requested_by_user_id", (object?)requestedByUserId ?? DBNull.Value),
            new("p_channel", channel),
            new("p_id_no", idNo),
            new("p_email", email),
            new("p_client_name", clientName),
            new("p_dob", dob),
            new("p_kra_pin", (object?)kraPin ?? DBNull.Value),
            new("p_destination", destination),
            new("p_travel_date_from", travelDateFrom),
            new("p_travel_date_to", travelDateTo),
            new("p_travelling_with_family", (object?)travellingWithFamily ?? DBNull.Value),
            new("p_trip_type", tripType),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            quoteRequestIdParam,
            refNoParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteRequestTravel_Create", parameters);
        return ToCreateResult(result, quoteRequestIdParam, refNoParam);
    }

    public async Task<StoredProcResult<QuoteRequestCreateResult?>> CreateDomesticAsync(
        long? clientId, long? requestedByUserId, string channel, string idNo, string email, string? detailsJson, string actorType, long actorId)
    {
        var quoteRequestIdParam = new MySqlParameter("o_quote_request_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };
        var refNoParam = new MySqlParameter("o_ref_no", MySqlDbType.VarChar, 20) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", (object?)clientId ?? DBNull.Value),
            new("p_requested_by_user_id", (object?)requestedByUserId ?? DBNull.Value),
            new("p_channel", channel),
            new("p_id_no", idNo),
            new("p_email", email),
            new("p_details_json", (object?)detailsJson ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            quoteRequestIdParam,
            refNoParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteRequestDomestic_Create", parameters);
        return ToCreateResult(result, quoteRequestIdParam, refNoParam);
    }

    public Task<StoredProcResult<QuoteRequest?>> GetByIdAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequest_GetById", parameters, MapRow);
    }

    public Task<StoredProcResult<QuoteRequestMedicalIndividualDetail?>> GetMedicalIndividualDetailAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequestMedicalIndividual_GetDetail", parameters, MapMedicalIndividualDetailRow);
    }

    public Task<StoredProcResult<QuoteRequestMedicalCorporateDetail?>> GetMedicalCorporateDetailAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequestMedicalCorporate_GetDetail", parameters, MapMedicalCorporateDetailRow);
    }

    public Task<StoredProcResult<QuoteRequestProfessionalIndemnityDetail?>> GetProfessionalIndemnityDetailAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequestProfessionalIndemnity_GetDetail", parameters, MapProfessionalIndemnityDetailRow);
    }

    public Task<StoredProcResult<QuoteRequestTravelDetail?>> GetTravelDetailAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequestTravel_GetDetail", parameters, MapTravelDetailRow);
    }

    public Task<StoredProcResult<QuoteRequestDomesticDetail?>> GetDomesticDetailAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteRequestDomestic_GetDetail", parameters, MapDomesticDetailRow);
    }

    public async Task<StoredProcResult<QuoteRequestListPage>> GetListAsync(
        string? status, long? assignedBackofficeUserId, long? productId, int pageNumber, int pageSize)
    {
        var totalCountParam = new MySqlParameter("o_total_count", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_status", (object?)status ?? DBNull.Value),
            new("p_assigned_backoffice_user_id", (object?)assignedBackofficeUserId ?? DBNull.Value),
            new("p_product_id", (object?)productId ?? DBNull.Value),
            new("p_page_number", pageNumber),
            new("p_page_size", pageSize),
            totalCountParam
        };

        var result = await _executor.ExecuteQueryAsync("usp_QuoteRequest_GetList", parameters, MapRow);

        var page = new QuoteRequestListPage
        {
            TotalCount = totalCountParam.Value is null or DBNull ? 0 : Convert.ToInt64(totalCountParam.Value),
            Items = result.Data ?? new List<QuoteRequest>()
        };

        return new StoredProcResult<QuoteRequestListPage>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = page
        };
    }

    public Task<StoredProcResult<List<QuoteRequestProductSummary>>> GetSummaryAsync()
    {
        return _executor.ExecuteQueryAsync("usp_QuoteRequest_GetSummary", new List<MySqlParameter>(), MapSummaryRow);
    }

    public Task<StoredProcResult> AssignBackofficeAsync(long quoteRequestId, long assignedBackofficeUserId, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_quote_request_id", quoteRequestId),
            new("p_assigned_backoffice_user_id", assignedBackofficeUserId),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_QuoteRequest_AssignBackoffice", parameters);
    }

    public Task<StoredProcResult> ExpireAsync(long quoteRequestId, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_quote_request_id", quoteRequestId),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_QuoteRequest_Expire", parameters);
    }

    private static StoredProcResult<QuoteRequestCreateResult?> ToCreateResult(StoredProcResult result, MySqlParameter idParam, MySqlParameter refNoParam)
    {
        var quoteRequestId = idParam.Value is null or DBNull ? (long?)null : Convert.ToInt64(idParam.Value);

        return new StoredProcResult<QuoteRequestCreateResult?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = quoteRequestId is null ? null : new QuoteRequestCreateResult
            {
                QuoteRequestId = quoteRequestId.Value,
                RefNo = refNoParam.Value is null or DBNull ? null : (string)refNoParam.Value
            }
        };
    }

    private static QuoteRequest MapRow(MySqlDataReader reader)
    {
        return new QuoteRequest
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            RefNo = reader.IsDBNull(reader.GetOrdinal("ref_no")) ? null : reader.GetString("ref_no"),
            ProductId = reader.GetInt64("product_id"),
            ProductCode = reader.GetString("product_code"),
            ClientId = reader.IsDBNull(reader.GetOrdinal("client_id")) ? null : reader.GetInt64("client_id"),
            RequestedByUserId = reader.IsDBNull(reader.GetOrdinal("requested_by_user_id")) ? null : reader.GetInt64("requested_by_user_id"),
            Channel = reader.GetString("channel"),
            Status = reader.GetString("status"),
            AssignedBackofficeUserId = reader.IsDBNull(reader.GetOrdinal("assigned_backoffice_user_id")) ? null : reader.GetInt64("assigned_backoffice_user_id"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static QuoteRequestMedicalIndividualDetail MapMedicalIndividualDetailRow(MySqlDataReader reader)
    {
        return new QuoteRequestMedicalIndividualDetail
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            FirstName = reader.GetString("first_name"),
            LastName = reader.GetString("last_name"),
            OtherNames = reader.IsDBNull(reader.GetOrdinal("other_names")) ? null : reader.GetString("other_names"),
            FamilyMembers = ParseFamilyMembers(reader.IsDBNull(reader.GetOrdinal("family_members_json")) ? null : reader.GetString("family_members_json")),
            IdNo = reader.GetString("id_no"),
            Email = reader.GetString("email"),
            MobileNumber = reader.GetString("mobile_number"),
            InpatientLimit = reader.GetDecimal("inpatient_limit"),
            HasOutpatient = reader.GetBoolean("has_outpatient"),
            OutpatientLimit = reader.IsDBNull(reader.GetOrdinal("outpatient_limit")) ? null : reader.GetDecimal("outpatient_limit"),
            HasDental = reader.GetBoolean("has_dental"),
            DentalLimit = reader.IsDBNull(reader.GetOrdinal("dental_limit")) ? null : reader.GetDecimal("dental_limit"),
            HasMaternity = reader.GetBoolean("has_maternity")
        };
    }

    // Tolerant on purpose - a malformed/legacy family_members_json value
    // (or one that predates this shape) returns null here rather than
    // throwing and failing the whole GetDetail call.
    private static List<FamilyMember>? ParseFamilyMembers(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<List<FamilyMember>>(json, JsonOptions.CamelCase);
        }
        catch (System.Text.Json.JsonException)
        {
            return null;
        }
    }

    private static QuoteRequestMedicalCorporateDetail MapMedicalCorporateDetailRow(MySqlDataReader reader)
    {
        return new QuoteRequestMedicalCorporateDetail
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            IdNo = reader.GetString("id_no"),
            CompanyName = reader.GetString("company_name"),
            Phone = reader.GetString("phone"),
            Email = reader.GetString("email")
        };
    }

    private static QuoteRequestProfessionalIndemnityDetail MapProfessionalIndemnityDetailRow(MySqlDataReader reader)
    {
        return new QuoteRequestProfessionalIndemnityDetail
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            IdNo = reader.GetString("id_no"),
            ClientOrCompanyName = reader.GetString("client_or_company_name"),
            Phone = reader.GetString("phone"),
            Email = reader.GetString("email"),
            Profession = reader.GetString("profession"),
            ProposalFormStatus = reader.IsDBNull(reader.GetOrdinal("proposal_form_status")) ? null : reader.GetString("proposal_form_status")
        };
    }

    private static QuoteRequestTravelDetail MapTravelDetailRow(MySqlDataReader reader)
    {
        return new QuoteRequestTravelDetail
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            IdNo = reader.GetString("id_no"),
            Email = reader.GetString("email"),
            ClientName = reader.GetString("client_name"),
            Dob = reader.GetDateTime("dob"),
            KraPin = reader.IsDBNull(reader.GetOrdinal("kra_pin")) ? null : reader.GetString("kra_pin"),
            Destination = reader.GetString("destination"),
            TravelDateFrom = reader.GetDateTime("travel_date_from"),
            TravelDateTo = reader.GetDateTime("travel_date_to"),
            TravellingWithFamily = reader.GetBoolean("travelling_with_family"),
            TripType = reader.GetString("trip_type")
        };
    }

    private static QuoteRequestProductSummary MapSummaryRow(MySqlDataReader reader)
    {
        // pending_count/in_progress_count come from SUM(boolean-expression),
        // which MySQL/MySqlConnector can hand back as DECIMAL rather than a
        // plain integer type - Convert.ToInt64 (not GetInt64, which requires
        // an exact type match) tolerates whichever numeric CLR type actually
        // comes back. The DBNull check covers an empty work queue: SUM over
        // zero rows is NULL on the SQL side (the proc COALESCEs, but this
        // keeps the mapper safe against older proc versions too).
        object? pending = reader["pending_count"];
        object? inProgress = reader["in_progress_count"];
        object? total = reader["total_count"];

        return new QuoteRequestProductSummary
        {
            ProductId = reader.GetInt64("product_id"),
            ProductCode = reader.GetString("product_code"),
            ProductName = reader.GetString("product_name"),
            PendingCount = pending is null or DBNull ? 0 : Convert.ToInt64(pending),
            InProgressCount = inProgress is null or DBNull ? 0 : Convert.ToInt64(inProgress),
            TotalCount = total is null or DBNull ? 0 : Convert.ToInt64(total)
        };
    }

    private static QuoteRequestDomesticDetail MapDomesticDetailRow(MySqlDataReader reader)
    {
        return new QuoteRequestDomesticDetail
        {
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            IdNo = reader.GetString("id_no"),
            Email = reader.GetString("email"),
            DetailsJson = reader.IsDBNull(reader.GetOrdinal("details_json")) ? null : reader.GetString("details_json")
        };
    }
}
