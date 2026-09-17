using System.Data;
using System.Text.Json;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class QuoteOfferRepository : IQuoteOfferRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public QuoteOfferRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(long quoteRequestId, long underwriterId, decimal premiumAmount, string? documentPath, long uploadedByUserId)
    {
        var quoteOfferIdParam = new MySqlParameter("o_quote_offer_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_quote_request_id", quoteRequestId),
            new("p_underwriter_id", underwriterId),
            new("p_premium_amount", premiumAmount),
            new("p_document_path", (object?)documentPath ?? DBNull.Value),
            new("p_uploaded_by_user_id", uploadedByUserId),
            quoteOfferIdParam
        };

        var result = await _executor.ExecuteAsync("usp_QuoteOffer_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = quoteOfferIdParam.Value is null or DBNull ? null : Convert.ToInt64(quoteOfferIdParam.Value)
        };
    }

    public Task<StoredProcResult<List<QuoteOffer>>> GetListByRequestAsync(long quoteRequestId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_request_id", quoteRequestId) };
        return _executor.ExecuteQueryAsync("usp_QuoteOffer_GetListByRequest", parameters, MapRow);
    }

    public Task<StoredProcResult> SelectAsync(long quoteOfferId, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_quote_offer_id", quoteOfferId),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_QuoteOffer_Select", parameters);
    }

    public Task<StoredProcResult> UpdateAsync(long quoteOfferId, long underwriterId, decimal premiumAmount, string? documentPath, bool replaceDocument, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_quote_offer_id", quoteOfferId),
            new("p_underwriter_id", underwriterId),
            new("p_premium_amount", premiumAmount),
            new("p_document_path", (object?)documentPath ?? DBNull.Value),
            new("p_replace_document", replaceDocument),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_QuoteOffer_Update", parameters);
    }

    public Task<StoredProcResult> DeleteAsync(long quoteOfferId, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_quote_offer_id", quoteOfferId),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_QuoteOffer_Delete", parameters);
    }

    public Task<StoredProcResult<QuoteOffer?>> GetByIdAsync(long quoteOfferId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_offer_id", quoteOfferId) };
        return _executor.ExecuteQuerySingleAsync("usp_QuoteOffer_GetById", parameters, MapRow);
    }

    public Task<StoredProcResult> ReplaceRidersAsync(long quoteOfferId, List<QuoteOfferRider> riders, long actorId)
    {
        var payloadJson = JsonSerializer.Serialize((riders ?? new())
            .Where(r => !string.IsNullOrWhiteSpace(r.Name))
            .Select(r => new
            {
                name = r.Name.Trim(),
                amount = r.Amount,
                note = string.IsNullOrWhiteSpace(r.Note) ? null : r.Note.Trim()
            }));

        var parameters = new List<MySqlParameter>
        {
            new("p_quote_offer_id", quoteOfferId),
            new("p_actor_id", actorId),
            new("p_addons_json", payloadJson)
        };

        return _executor.ExecuteAsync("usp_QuoteOfferRider_Replace", parameters);
    }

    public Task<StoredProcResult<List<QuoteOfferRider>>> GetRidersByOfferAsync(long quoteOfferId)
    {
        var parameters = new List<MySqlParameter> { new("p_quote_offer_id", quoteOfferId) };
        return _executor.ExecuteQueryAsync("usp_QuoteOfferRider_GetByOffer", parameters, MapRiderRow);
    }

    private static QuoteOfferRider MapRiderRow(MySqlDataReader reader)
    {
        return new QuoteOfferRider
        {
            RiderId = reader.GetInt64("rider_id"),
            QuoteOfferId = reader.GetInt64("quote_offer_id"),
            Name = reader.GetString("name"),
            Amount = reader.IsDBNull(reader.GetOrdinal("amount")) ? null : reader.GetDecimal("amount"),
            Note = reader.IsDBNull(reader.GetOrdinal("note")) ? null : reader.GetString("note"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static QuoteOffer MapRow(MySqlDataReader reader)
    {
        return new QuoteOffer
        {
            QuoteOfferId = reader.GetInt64("quote_offer_id"),
            QuoteRequestId = reader.GetInt64("quote_request_id"),
            UnderwriterId = reader.GetInt64("underwriter_id"),
            UnderwriterName = reader.GetString("underwriter_name"),
            PremiumAmount = reader.GetDecimal("premium_amount"),
            DocumentPath = reader.IsDBNull(reader.GetOrdinal("document_path")) ? null : reader.GetString("document_path"),
            UploadedByUserId = reader.GetInt64("uploaded_by_user_id"),
            UploadedOn = reader.GetDateTime("uploaded_on"),
            Status = reader.GetString("status")
        };
    }
}
