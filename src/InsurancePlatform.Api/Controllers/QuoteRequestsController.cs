using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Quotes;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Api.Services;
using InsurancePlatform.Application.Notifications;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Quote workflow for the five non-Motor products - requests, detail lookup, and back-office offers.</summary>
// Motor (TPO/Comprehensive) never goes through here - it's priced directly
// via PricingController, no QuoteRequests row needed.
//
// Create/GetById/GetDetail/GetOffers are [Authorize]-only (no specific
// permission code) - a Client requesting their own quote, an Agent/
// AgentAdmin/SupportAgent requesting on a client's behalf, and a USSD/
// WhatsApp channel-service account are all legitimate callers. A
// Client-role caller is restricted to quote requests linked to their OWN
// client_id (CallerOwnsClientRecordAsync below) - staff and channel-service
// callers aren't restricted at this layer.
//
// GetList/AssignBackoffice/Expire are the back-office work-queue actions -
// restricted to SuperAdmin/AgentAdmin/SupportAgent, since "assigned_backoffice_user_id"
// is explicitly a backoffice concept, not something an Agent manages.
// CreateOffer is the same backoffice group ("back office uploads a priced
// option"); Select is [Authorize]-only, since the client/agent who owns the
// request is the one picking an offer, not backoffice staff.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QuoteRequestsController : BaseApiController
{
    private readonly IQuoteRequestRepository _quoteRequestRepository;
    private readonly IQuoteOfferRepository _quoteOfferRepository;
    private readonly IClientRepository _clientRepository;
    private readonly IUserRepository _userRepository;
    private readonly IQuoteOfferDocumentStorage _documentStorage;
    private readonly IQuoteNotificationSender _notificationSender;
    private readonly ILoggerManager _logger;

    /// <summary>
    /// Only needed for SendOffersComparisonEmailAsync, which has to read an
    /// offer's document back off disk (WebRootPath) so it can be copied
    /// into the Scapi-visible attachment folder - see
    /// LocalQuoteOfferDocumentStorage's own use of the same WebRootPath
    /// resolution for how it landed there in the first place.
    /// </summary>
    private readonly IWebHostEnvironment _env;

    /// <summary>
    /// Only needed for SendOffersComparisonEmailAsync, to read
    /// ScapiGateway:OffersAttachmentPath - see that method's own comment
    /// for what this config key is for.
    /// </summary>
    private readonly IConfiguration _configuration;

    private const string BackofficeRoles = $"{RoleCodes.SuperAdmin},{RoleCodes.AgentAdmin},{RoleCodes.SupportAgent}";

    public QuoteRequestsController(
        IQuoteRequestRepository quoteRequestRepository,
        IQuoteOfferRepository quoteOfferRepository,
        IClientRepository clientRepository,
        IUserRepository userRepository,
        IQuoteOfferDocumentStorage documentStorage,
        IQuoteNotificationSender notificationSender,
        ILoggerManager logger,
        IWebHostEnvironment env,
        IConfiguration configuration,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _quoteRequestRepository = quoteRequestRepository;
        _quoteOfferRepository = quoteOfferRepository;
        _clientRepository = clientRepository;
        _userRepository = userRepository;
        _documentStorage = documentStorage;
        _notificationSender = notificationSender;
        _logger = logger;
        _env = env;
        _configuration = configuration;
    }

    /// <summary>Requests a Medical Individual quote. WEBSITE-only - the channel is hardcoded, not taken from the payload.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("medical-individual")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateMedicalIndividual([FromBody] CreateMedicalIndividualQuoteRequest request)
    {
        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        // 1. Customer Information: idNo, firstName, lastName, email and
        // mobileNumber are all required (otherNames is optional) - checked
        // here, before ever calling the repository, so a missing one gets a
        // clean, specific message instead of falling through to
        // usp_QuoteRequestMedicalIndividual_Create's own combined message.
        if (string.IsNullOrWhiteSpace(request.IdNo))
        {
            return BusinessFailure("idNo is required.");
        }

        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
        {
            return BusinessFailure("firstName and lastName are required.");
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return BusinessFailure("email is required.");
        }

        if (string.IsNullOrWhiteSpace(request.MobileNumber))
        {
            return BusinessFailure("mobileNumber is required.");
        }

        // 2. Coverage Details: inpatient limit is mandatory and must be positive.
        if (request.InpatientLimit <= 0)
        {
            return BusinessFailure("inpatientLimit is required and must be greater than zero.");
        }

        // 3. Optional Benefits: a limit must accompany an enabled benefit,
        // and limits may only be sent for enabled benefits. Maternity is yes/no only.
        decimal? outpatientLimit = null;
        decimal? dentalLimit = null;

        var optionalBenefits = request.OptionalBenefits;
        if (optionalBenefits?.Outpatient is { Enabled: true } outpatient)
        {
            if (outpatient.Limit is not > 0)
            {
                return BusinessFailure("outpatient limit is required when the Outpatient benefit is enabled.");
            }

            outpatientLimit = outpatient.Limit;
        }
        else if (optionalBenefits?.Outpatient?.Limit is not null)
        {
            return BusinessFailure("outpatient limit can only be set when the Outpatient benefit is enabled.");
        }

        if (optionalBenefits?.Dental is { Enabled: true } dental)
        {
            if (dental.Limit is not > 0)
            {
                return BusinessFailure("dental limit is required when the Dental benefit is enabled.");
            }

            dentalLimit = dental.Limit;
        }
        else if (optionalBenefits?.Dental?.Limit is not null)
        {
            return BusinessFailure("dental limit can only be set when the Dental benefit is enabled.");
        }

        var familyMembersJson = SerializeFamilyMembers(request.FamilyMembers, out var validationError);
        if (validationError is not null)
        {
            return BusinessFailure(validationError);
        }

        var (actorType, actorId, requestedByUserId) = ResolveActor();

        var result = await _quoteRequestRepository.CreateMedicalIndividualAsync(
            request.ClientId, requestedByUserId,
            request.IdNo.Trim(), request.FirstName.Trim(), request.LastName.Trim(),
            string.IsNullOrWhiteSpace(request.OtherNames) ? null : request.OtherNames!.Trim(),
            request.Email!.Trim(), request.MobileNumber.Trim(),
            request.InpatientLimit,
            optionalBenefits?.Outpatient is { Enabled: true }, outpatientLimit,
            optionalBenefits?.Dental is { Enabled: true }, dentalLimit,
            optionalBenefits?.Maternity ?? false,
            familyMembersJson, actorType, actorId);

        await NotifyQuoteRequestCreatedAsync(result, "MED_IND", "Medical Individual/Family", $"{request.FirstName} {request.LastName}", request.Email!);

        return CreateResult(result, "MED_IND");
    }

    /// <summary>Validates Relationship values (Spouse/Child, case-insensitive, at most one Spouse) and serializes the list to the JSON string the repository/proc expect - null in, null out.</summary>
    private static string? SerializeFamilyMembers(List<FamilyMemberDto>? members, out string? validationError)
    {
        validationError = null;

        if (members is null || members.Count == 0)
        {
            return null;
        }

        var spouseCount = 0;
        foreach (var member in members)
        {
            if (string.Equals(member.Relationship, "Spouse", StringComparison.OrdinalIgnoreCase))
            {
                spouseCount++;
            }
            else if (!string.Equals(member.Relationship, "Child", StringComparison.OrdinalIgnoreCase))
            {
                validationError = $"Invalid family member relationship '{member.Relationship}' - must be 'Spouse' or 'Child'.";
                return null;
            }

            if (string.IsNullOrWhiteSpace(member.FullName))
            {
                validationError = "Each family member requires a FullName.";
                return null;
            }
        }

        if (spouseCount > 1)
        {
            validationError = "At most one Spouse is allowed per quote request.";
            return null;
        }

        // Fully-qualified on purpose - this file already has "using
        // Microsoft.AspNetCore.Mvc;", which brings in its own unrelated
        // Microsoft.AspNetCore.Mvc.JsonOptions type (MVC's JSON formatter
        // settings). A bare "JsonOptions" here would be an ambiguous
        // reference between that and our InsurancePlatform.Domain.Common
        // one - the full name sidesteps the collision entirely.
        return System.Text.Json.JsonSerializer.Serialize(members, InsurancePlatform.Domain.Common.JsonOptions.CamelCase);
    }

    /// <summary>Requests a Medical Corporate quote.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("medical-corporate")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateMedicalCorporate([FromBody] CreateMedicalCorporateQuoteRequest request)
    {
        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        if (string.IsNullOrWhiteSpace(request.IdNo) || string.IsNullOrWhiteSpace(request.Email))
        {
            return BusinessFailure("idNo and email are both required.");
        }

        var (actorType, actorId, requestedByUserId) = ResolveActor();

        var result = await _quoteRequestRepository.CreateMedicalCorporateAsync(
            request.ClientId, requestedByUserId, request.Channel, request.IdNo, request.CompanyName, request.Phone,
            request.Email, actorType, actorId);

        await NotifyQuoteRequestCreatedAsync(result, "MED_CORP", "Medical Corporate", request.CompanyName, request.Email);

        return CreateResult(result, "MED_CORP");
    }

    /// <summary>Requests a Professional Indemnity quote.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("professional-indemnity")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateProfessionalIndemnity([FromBody] CreateProfessionalIndemnityQuoteRequest request)
    {
        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        if (string.IsNullOrWhiteSpace(request.IdNo) || string.IsNullOrWhiteSpace(request.Email))
        {
            return BusinessFailure("idNo and email are both required.");
        }

        var (actorType, actorId, requestedByUserId) = ResolveActor();

        var result = await _quoteRequestRepository.CreateProfessionalIndemnityAsync(
            request.ClientId, requestedByUserId, request.Channel, request.IdNo, request.ClientOrCompanyName, request.Phone,
            request.Email, request.Profession, actorType, actorId);

        await NotifyQuoteRequestCreatedAsync(result, "PI", "Professional Indemnity", request.ClientOrCompanyName, request.Email);

        return CreateResult(result, "PI");
    }

    /// <summary>Requests a Travel quote.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("travel")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateTravel([FromBody] CreateTravelQuoteRequest request)
    {
        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        if (string.IsNullOrWhiteSpace(request.IdNo) || string.IsNullOrWhiteSpace(request.Email))
        {
            return BusinessFailure("idNo and email are both required.");
        }

        var (actorType, actorId, requestedByUserId) = ResolveActor();

        var result = await _quoteRequestRepository.CreateTravelAsync(
            request.ClientId, requestedByUserId, request.Channel, request.IdNo, request.Email, request.ClientName, request.Dob,
            request.KraPin, request.Destination, request.TravelDateFrom, request.TravelDateTo,
            request.TravellingWithFamily, request.TripType, actorType, actorId);

        await NotifyQuoteRequestCreatedAsync(result, "TRAVEL", "Travel", request.ClientName, request.Email);

        return CreateResult(result, "TRAVEL");
    }

    /// <summary>Requests a Domestic quote. TEMPORARY details_json shape until real fields are confirmed.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("domestic")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateDomestic([FromBody] CreateDomesticQuoteRequest request)
    {
        if (!await CallerOwnsClientRecordAsync(request.ClientId))
        {
            return BusinessFailure("Client not found.");
        }

        if (string.IsNullOrWhiteSpace(request.IdNo) || string.IsNullOrWhiteSpace(request.Email))
        {
            return BusinessFailure("idNo and email are both required.");
        }

        var (actorType, actorId, requestedByUserId) = ResolveActor();

        var result = await _quoteRequestRepository.CreateDomesticAsync(
            request.ClientId, requestedByUserId, request.Channel, request.IdNo, request.Email, request.DetailsJson, actorType, actorId);

        await NotifyQuoteRequestCreatedAsync(result, "DOMESTIC", "Domestic", request.IdNo, request.Email);

        return CreateResult(result, "DOMESTIC");
    }

    /// <summary>Fetches the shared parent row - read ProductCode to know which detail type applies.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<QuoteRequest>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(long id)
    {
        var result = await _quoteRequestRepository.GetByIdAsync(id);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        if (!await CallerOwnsClientRecordAsync(result.Data.ClientId))
        {
            return BusinessFailure("Quote request not found.");
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Fetches the type-specific detail row - looks up ProductCode internally, no need to call GetById first.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}/detail")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDetail(long id)
    {
        var parentResult = await _quoteRequestRepository.GetByIdAsync(id);

        if (!parentResult.IsSuccess || parentResult.Data is null)
        {
            return BusinessFailure(parentResult.ResultMessage);
        }

        if (!await CallerOwnsClientRecordAsync(parentResult.Data.ClientId))
        {
            return BusinessFailure("Quote request not found.");
        }

        // Product codes here match the literal strings usp_QuoteRequest<Type>_Create
        // looks up in Products.code (see Insurance_API_StoredProcs_Quotes.sql).
        switch (parentResult.Data.ProductCode)
        {
            case "MED_IND":
                var medIndResult = await _quoteRequestRepository.GetMedicalIndividualDetailAsync(id);
                return medIndResult.Data is null ? BusinessFailure("Detail not found.") : Success<object>(medIndResult.Data, medIndResult.ResultMessage);
            case "MED_CORP":
                var medCorpResult = await _quoteRequestRepository.GetMedicalCorporateDetailAsync(id);
                return medCorpResult.Data is null ? BusinessFailure("Detail not found.") : Success<object>(medCorpResult.Data, medCorpResult.ResultMessage);
            case "PI":
                var piResult = await _quoteRequestRepository.GetProfessionalIndemnityDetailAsync(id);
                return piResult.Data is null ? BusinessFailure("Detail not found.") : Success<object>(piResult.Data, piResult.ResultMessage);
            case "TRAVEL":
                var travelResult = await _quoteRequestRepository.GetTravelDetailAsync(id);
                return travelResult.Data is null ? BusinessFailure("Detail not found.") : Success<object>(travelResult.Data, travelResult.ResultMessage);
            case "DOMESTIC":
                var domesticResult = await _quoteRequestRepository.GetDomesticDetailAsync(id);
                return domesticResult.Data is null ? BusinessFailure("Detail not found.") : Success<object>(domesticResult.Data, domesticResult.ResultMessage);
            default:
                _logger.LogError($"GET /api/quoterequests/{id}/detail - unrecognized product_code '{parentResult.Data.ProductCode}'.");
                return ServerError("Unrecognized product for this quote request.");
        }
    }

    /// <summary>Back-office work queue - unassigned/PENDING requests, or one back-office user's assigned queue.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<QuoteRequestListPage>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] string? status, [FromQuery] long? assignedBackofficeUserId, [FromQuery] long? productId,
        [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _quoteRequestRepository.GetListAsync(status, assignedBackofficeUserId, productId, pageNumber, pageSize);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_QuoteRequest_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Per-product pending/in-progress/total counts for the list screen's summary header.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<List<QuoteRequestProductSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSummary()
    {
        var result = await _quoteRequestRepository.GetSummaryAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_QuoteRequest_GetSummary returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Assigns a quote request to a back-office user and moves it to IN_PROGRESS.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPut("{id}/assign")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> AssignBackoffice(long id, [FromBody] AssignQuoteRequestBackofficeRequest request)
    {
        var result = await _quoteRequestRepository.AssignBackofficeAsync(id, request.AssignedBackofficeUserId, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote request assigned: quote_request_id={id}, assigned_to={request.AssignedBackofficeUserId}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Marks a quote request EXPIRED.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPut("{id}/expire")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Expire(long id)
    {
        var result = await _quoteRequestRepository.ExpireAsync(id, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote request expired: quote_request_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Back office uploads a priced option from one underwriter, with an optional supporting document.</summary>
    // Also flips the parent QuoteRequests row to QUOTED the first time an
    // offer is added - handled inside usp_QuoteOffer_Create itself, not here.
    // [FromForm] (not [FromBody]) because Document is a real uploaded file -
    // the request arrives as multipart/form-data, not JSON.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPost("{id}/offers")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateOffer(long id, [FromForm] CreateQuoteOfferRequest request)
    {
        string? documentPath = null;
        if (request.Document is not null)
        {
            try
            {
                documentPath = await _documentStorage.SaveAsync(request.Document);
            }
            catch (InvalidOperationException ex)
            {
                return BusinessFailure(ex.Message);
            }
        }

        var result = await _quoteOfferRepository.CreateAsync(id, request.UnderwriterId, request.PremiumAmount, documentPath, CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Quote offer create failed for quote_request_id={id}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote offer created: quote_offer_id={result.Data}, quote_request_id={id}, by user_id={CurrentUserId}.");
        return Success(new { QuoteOfferId = result.Data }, result.ResultMessage);
    }

    /// <summary>
    /// Back office uploads several priced options in one submission - "add
    /// multiple, submit once" instead of one POST per offer (per the
    /// feature request). Bound with [FromForm] for the same reason as the
    /// single-offer CreateOffer above - each row's Document is a real
    /// uploaded file, so the whole request has to travel as multipart/
    /// form-data with indexed field names (Offers[0].UnderwriterId,
    /// Offers[0].Document, Offers[1]..., ...), which ASP.NET Core's default
    /// form binder handles natively.
    ///
    /// Best-effort per row, not all-or-nothing: one bad row (unsupported
    /// file type, an underwriter_id that doesn't exist, etc.) doesn't stop
    /// the rest of the batch - each row's own success/failure is
    /// independent (same as calling CreateOffer once per row yourself), and
    /// every per-row error is collected and returned alongside whatever did
    /// succeed. The comparison email (SendOffersComparisonEmailAsync) only
    /// fires once at the very end, and only if at least one row succeeded -
    /// no point emailing the client a comparison of zero new offers.
    /// </summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPost("{id}/offers/batch")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateOffersBatch(long id, [FromForm] CreateQuoteOfferBatchRequest request)
    {
        if (request.Offers is null || request.Offers.Count == 0)
        {
            return BusinessFailure("At least one offer is required.");
        }

        var createdIds = new List<long>();
        var errors = new List<string>();

        for (var index = 0; index < request.Offers.Count; index++)
        {
            var item = request.Offers[index];
            string? documentPath = null;

            if (item.Document is not null)
            {
                try
                {
                    documentPath = await _documentStorage.SaveAsync(item.Document);
                }
                catch (InvalidOperationException ex)
                {
                    errors.Add($"Offer {index + 1}: {ex.Message}");
                    continue;
                }
            }

            var result = await _quoteOfferRepository.CreateAsync(id, item.UnderwriterId, item.PremiumAmount, documentPath, CurrentUserId);

            if (!result.IsSuccess || result.Data is null)
            {
                errors.Add($"Offer {index + 1}: {result.ResultMessage}");
                continue;
            }

            createdIds.Add(result.Data.Value);
        }

        if (errors.Count > 0)
        {
            _logger.LogWarn($"Quote offer batch create had {errors.Count} of {request.Offers.Count} row(s) fail for quote_request_id={id}: {string.Join(" | ", errors)}");
        }

        if (createdIds.Count == 0)
        {
            return BusinessFailure(errors.Count > 0 ? string.Join(" ", errors) : "No offers were created.");
        }

        _logger.LogInfo($"Quote offer batch created: {createdIds.Count} of {request.Offers.Count} offer(s) for quote_request_id={id}, by user_id={CurrentUserId}.");

        // Best-effort, same reasoning as NotifyQuoteRequestCreatedAsync -
        // never let a notification-email problem turn an otherwise-successful
        // offer upload into a failure response.
        await SendOffersComparisonEmailAsync(id);

        return Success(new { CreatedCount = createdIds.Count, QuoteOfferIds = createdIds, Errors = errors }, "Offer(s) created.");
    }

    /// <summary>
    /// Back office edits several ACTIVE offers on the same quote request in
    /// one submission - the batch equivalent of UpdateOffer below. Root-
    /// addressed (not nested under {id}/offers) since each row already
    /// carries its own QuoteOfferId; QuoteRequestId only exists at the top
    /// level of the request body so the comparison email can be sent once
    /// at the end rather than once per edited row. Same best-effort,
    /// per-row-independent behavior as CreateOffersBatch above.
    /// </summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPut("/api/quote-offers/batch")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateOffersBatch([FromForm] UpdateQuoteOfferBatchRequest request)
    {
        if (request.Offers is null || request.Offers.Count == 0)
        {
            return BusinessFailure("At least one offer is required.");
        }

        var updatedCount = 0;
        var errors = new List<string>();

        for (var index = 0; index < request.Offers.Count; index++)
        {
            var item = request.Offers[index];
            string? documentPath = null;
            var replaceDocument = false;

            if (item.Document is not null)
            {
                try
                {
                    documentPath = await _documentStorage.SaveAsync(item.Document);
                    replaceDocument = true;
                }
                catch (InvalidOperationException ex)
                {
                    errors.Add($"Offer {index + 1} (id={item.QuoteOfferId}): {ex.Message}");
                    continue;
                }
            }

            var result = await _quoteOfferRepository.UpdateAsync(item.QuoteOfferId, item.UnderwriterId, item.PremiumAmount, documentPath, replaceDocument, CurrentUserId);

            if (!result.IsSuccess)
            {
                errors.Add($"Offer {index + 1} (id={item.QuoteOfferId}): {result.ResultMessage}");
                continue;
            }

            updatedCount++;
        }

        if (errors.Count > 0)
        {
            _logger.LogWarn($"Quote offer batch update had {errors.Count} of {request.Offers.Count} row(s) fail for quote_request_id={request.QuoteRequestId}: {string.Join(" | ", errors)}");
        }

        if (updatedCount == 0)
        {
            return BusinessFailure(errors.Count > 0 ? string.Join(" ", errors) : "No offers were updated.");
        }

        _logger.LogInfo($"Quote offer batch updated: {updatedCount} of {request.Offers.Count} offer(s) for quote_request_id={request.QuoteRequestId}, by user_id={CurrentUserId}.");

        await SendOffersComparisonEmailAsync(request.QuoteRequestId);

        return Success(new { UpdatedCount = updatedCount, Errors = errors }, "Offer(s) updated.");
    }

    /// <summary>Lists every offer uploaded against a quote request, cheapest first.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}/offers")]
    [ProducesResponseType(typeof(ApiResponse<List<QuoteOffer>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOffers(long id)
    {
        var parentResult = await _quoteRequestRepository.GetByIdAsync(id);

        if (!parentResult.IsSuccess || parentResult.Data is null)
        {
            return BusinessFailure(parentResult.ResultMessage);
        }

        if (!await CallerOwnsClientRecordAsync(parentResult.Data.ClientId))
        {
            return BusinessFailure("Quote request not found.");
        }

        var result = await _quoteOfferRepository.GetListByRequestAsync(id);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_QuoteOffer_GetListByRequest returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>
    /// Streams an offer's uploaded document back to the caller - the
    /// authenticated replacement for serving wwwroot/uploads/quote-offers
    /// via static files (files now live in the shared folder configured at
    /// QuoteOffersStorage:Root, outside webroot, so they're NOT publicly
    /// reachable by URL anymore). Same ownership rules as GetOffers.
    /// </summary>
    [HttpGet("{id}/offers/{quoteOfferId}/document")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DownloadOfferDocument(long id, long quoteOfferId)
    {
        var parentResult = await _quoteRequestRepository.GetByIdAsync(id);

        if (!parentResult.IsSuccess || parentResult.Data is null)
        {
            return BusinessFailure(parentResult.ResultMessage);
        }

        if (!await CallerOwnsClientRecordAsync(parentResult.Data.ClientId))
        {
            return BusinessFailure("Quote request not found.");
        }

        var offersResult = await _quoteOfferRepository.GetListByRequestAsync(id);

        if (!offersResult.IsSuccess || offersResult.Data is null)
        {
            return BusinessFailure("Offers not found for this quote request.");
        }

        var offer = offersResult.Data.FirstOrDefault(o => o.QuoteOfferId == quoteOfferId);

        if (offer is null)
        {
            return BusinessFailure("Offer not found on this quote request.");
        }

        if (string.IsNullOrWhiteSpace(offer.DocumentPath))
        {
            return BusinessFailure("This offer has no uploaded document.");
        }

        var stream = await _documentStorage.OpenAsync(offer.DocumentPath);

        if (stream is null)
        {
            _logger.LogWarn($"GET offers/{quoteOfferId}/document - file missing on disk: {offer.DocumentPath}.");
            return BusinessFailure("Document file is missing on disk.");
        }

        // FileStreamResult disposes the stream when the response completes.
        return File(stream, ContentTypeForPath(offer.DocumentPath));
    }

    /// <summary>Content type by extension - matches the extensions LocalQuoteOfferDocumentStorage allows on upload.</summary>
    private static string ContentTypeForPath(string path) => Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".pdf" => "application/pdf",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".png" => "image/png",
        ".doc" => "application/msword",
        ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        _ => "application/octet-stream"
    };

    /// <summary>Picks one offer - marks it SELECTED, rejects the other still-ACTIVE offers on the same request.</summary>
    // Root-addressed by quote_offer_id (like VehiclesController's GetById/
    // Update/Delete) rather than nested under quote-requests/{id} - once you
    // have a quote_offer_id you don't need its owning quote_request_id.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPut("/api/quote-offers/{quoteOfferId}/select")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SelectOffer(long quoteOfferId)
    {
        var (actorType, actorId, _) = ResolveActor();

        var result = await _quoteOfferRepository.SelectAsync(quoteOfferId, actorType, actorId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote offer selected: quote_offer_id={quoteOfferId}, by {actorType.ToLowerInvariant()}_id={actorId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>
    /// Root-addressed document download by quote_offer_id only (no need to
    /// know the parent quote_request_id). Used by AdminPortal's DownloadOffer
    /// proxy which only has the offer id.
    /// </summary>
    [HttpGet("/api/quote-offers/{quoteOfferId}/document")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DownloadOfferDocumentByOfferId(long quoteOfferId)
    {
        var offerResult = await _quoteOfferRepository.GetByIdAsync(quoteOfferId);

        if (!offerResult.IsSuccess || offerResult.Data is null)
        {
            return BusinessFailure(offerResult.ResultMessage);
        }

        var offer = offerResult.Data;

        if (string.IsNullOrWhiteSpace(offer.DocumentPath))
        {
            return BusinessFailure("This offer has no uploaded document.");
        }

        var stream = await _documentStorage.OpenAsync(offer.DocumentPath);

        if (stream is null)
        {
            _logger.LogWarn($"GET /api/quote-offers/{quoteOfferId}/document - file missing on disk: {offer.DocumentPath}.");
            return BusinessFailure("Document file is missing on disk.");
        }

        return File(stream, ContentTypeForPath(offer.DocumentPath));
    }

    /// <summary>Edits an ACTIVE offer's underwriter/premium, and optionally replaces its document.</summary>
    // Same root-addressed-by-quote_offer_id shape as SelectOffer above.
    // Document is optional here for a different reason than on Create: a
    // missing/absent Document means "leave the existing file alone" (the
    // "just fixed a typo in the premium" case), not "delete the document" -
    // replaceDocument only turns true when a new file was actually posted.
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpPut("/api/quote-offers/{quoteOfferId}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateOffer(long quoteOfferId, [FromForm] UpdateQuoteOfferRequest request)
    {
        string? documentPath = null;
        var replaceDocument = false;

        if (request.Document is not null)
        {
            try
            {
                documentPath = await _documentStorage.SaveAsync(request.Document);
                replaceDocument = true;
            }
            catch (InvalidOperationException ex)
            {
                return BusinessFailure(ex.Message);
            }
        }

        var result = await _quoteOfferRepository.UpdateAsync(quoteOfferId, request.UnderwriterId, request.PremiumAmount, documentPath, replaceDocument, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote offer updated: quote_offer_id={quoteOfferId}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Soft-deletes an ACTIVE offer. Drops the parent request back to IN_PROGRESS if that was the last one (handled inside usp_QuoteOffer_Delete).</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Roles = BackofficeRoles)]
    [HttpDelete("/api/quote-offers/{quoteOfferId}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DeleteOffer(long quoteOfferId)
    {
        var result = await _quoteOfferRepository.DeleteAsync(quoteOfferId, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote offer deleted: quote_offer_id={quoteOfferId}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    private IActionResult CreateResult(StoredProcResult<QuoteRequestCreateResult?> result, string productCode)
    {
        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Quote request create failed for product={productCode}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Quote request created: quote_request_id={result.Data?.QuoteRequestId}, ref_no={result.Data?.RefNo}, product={productCode}, by user_id={CurrentUserId}.");
        return Success(new { QuoteRequestId = result.Data?.QuoteRequestId, RefNo = result.Data?.RefNo }, result.ResultMessage);
    }

    /// <summary>
    /// Fires the two "a quote request was just created" emails - one to the
    /// requester (client-received), one to every active Support/AgentAdmin
    /// user (new-quote-needs-processing). Called from all 5 CreateXXX
    /// actions right after a successful create, BEFORE returning
    /// CreateResult - deliberately best-effort: any failure here (gateway
    /// down, a bad staff email, whatever) is logged and swallowed, never
    /// turned into a BusinessFailure/500 for the caller. The quote request
    /// itself already exists in the database by the time this runs; a
    /// notification email failing is not a reason to tell the caller their
    /// request failed.
    /// </summary>
    private async Task NotifyQuoteRequestCreatedAsync(StoredProcResult<QuoteRequestCreateResult?> result, string productCode, string productName,string requesterName, string requesterEmail)
    {
        if (!result.IsSuccess || result.Data is null)
        {
            return;
        }

        var quoteRequestId = result.Data.QuoteRequestId;
        var refNo = result.Data.RefNo ?? quoteRequestId.ToString();

        try
        {
            var clientExternalRef = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
            var clientSent = await _notificationSender.SendQuoteReceivedEmailAsync(requesterEmail, requesterName, refNo, productName, clientExternalRef);
            if (!clientSent)
            {
                _logger.LogWarn($"Quote-received email failed to send for quote_request_id={quoteRequestId}, ref_no={refNo}, product={productCode}.");
            }
        }
        catch (Exception ex)
        {
            // Never let a Scapi/network exception here take down the actual
            // "your quote request was created" response - same reasoning as
            // the try/catch-free but always-tolerant pattern the rest of
            // this codebase uses for gateway calls (SendXxxAsync methods
            // return bool rather than throw on a failed send; this guards
            // the rarer case of the call itself throwing, e.g. a DNS/timeout
            // exception from the underlying HttpClient).
            _logger.LogError($"Quote-received email threw for quote_request_id={quoteRequestId}, ref_no={refNo}.", ex);
        }

        List<StaffOption> staffRecipients;
        try
        {
            staffRecipients = await GetBackofficeNotificationRecipientsAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError($"Could not resolve backoffice staff emails for quote_request_id={quoteRequestId} new-quote notification.", ex);
            return;
        }

        foreach (var staff in staffRecipients)
        {
            if (string.IsNullOrWhiteSpace(staff.Email))
            {
                continue;
            }

            try
            {
                var staffExternalRef = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
                var sent = await _notificationSender.SendNewQuoteStaffNotificationAsync(staff.Email!, refNo, productName, requesterName, staffExternalRef);
                if (!sent)
                {
                    _logger.LogWarn($"Staff new-quote email failed to send to {staff.Email} for quote_request_id={quoteRequestId}.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Staff new-quote email threw sending to {staff.Email} for quote_request_id={quoteRequestId}.", ex);
            }
        }
    }

    /// <summary>Every active Support Agent + Agent Admin user - "all support and Agent Admin emails" per the feature request. usp_User_GetList only filters by one role_code at a time, so this runs it twice (in parallel) and merges - same approach StaffController's own GetList already exposes for a single role.</summary>
    private async Task<List<StaffOption>> GetBackofficeNotificationRecipientsAsync()
    {
        var supportTask = _userRepository.GetListAsync(RoleCodes.SupportAgent, null, "ACTIVE", 1, 500);
        var agentAdminTask = _userRepository.GetListAsync(RoleCodes.AgentAdmin, null, "ACTIVE", 1, 500);
        await Task.WhenAll(supportTask, agentAdminTask);

        var recipients = new List<StaffOption>();
        if (supportTask.Result.IsSuccess && supportTask.Result.Data is not null)
        {
            recipients.AddRange(supportTask.Result.Data);
        }
        if (agentAdminTask.Result.IsSuccess && agentAdminTask.Result.Data is not null)
        {
            recipients.AddRange(agentAdminTask.Result.Data);
        }

        return recipients;
    }

    /// <summary>
    /// Fires once after a batch create/update of offers - "here are the
    /// options available, kindly compare and decide" - sent to the
    /// requester's own email with every currently-ACTIVE offer's underwriter/
    /// premium listed and its document attached (where one exists).
    /// Best-effort, same reasoning/shape as NotifyQuoteRequestCreatedAsync:
    /// wrapped in one big try/catch, every failure logged and swallowed,
    /// never turned into a BusinessFailure for the create/update call that
    /// triggered it - the offers themselves are already saved in the
    /// database by the time this runs, so a notification-email problem here
    /// is not a reason to tell the back-office user their upload failed.
    /// </summary>
    private async Task SendOffersComparisonEmailAsync(long quoteRequestId)
    {
        try
        {
            var parentResult = await _quoteRequestRepository.GetByIdAsync(quoteRequestId);
            if (!parentResult.IsSuccess || parentResult.Data is null)
            {
                _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: parent request not found.");
                return;
            }

            // Same ProductCode switch GetDetail uses above, just pulling out
            // requester name/email instead of returning the whole detail row.
            string requesterName;
            string requesterEmail;

            switch (parentResult.Data.ProductCode)
            {
                case "MED_IND":
                    var medInd = await _quoteRequestRepository.GetMedicalIndividualDetailAsync(quoteRequestId);
                    if (medInd.Data is null)
                    {
                        _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: MED_IND detail not found.");
                        return;
                    }
                    requesterName = medInd.Data.FullName;
                    requesterEmail = medInd.Data.Email;
                    break;
                case "MED_CORP":
                    var medCorp = await _quoteRequestRepository.GetMedicalCorporateDetailAsync(quoteRequestId);
                    if (medCorp.Data is null)
                    {
                        _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: MED_CORP detail not found.");
                        return;
                    }
                    requesterName = medCorp.Data.CompanyName;
                    requesterEmail = medCorp.Data.Email;
                    break;
                case "PI":
                    var pi = await _quoteRequestRepository.GetProfessionalIndemnityDetailAsync(quoteRequestId);
                    if (pi.Data is null)
                    {
                        _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: PI detail not found.");
                        return;
                    }
                    requesterName = pi.Data.ClientOrCompanyName;
                    requesterEmail = pi.Data.Email;
                    break;
                case "TRAVEL":
                    var travel = await _quoteRequestRepository.GetTravelDetailAsync(quoteRequestId);
                    if (travel.Data is null)
                    {
                        _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: TRAVEL detail not found.");
                        return;
                    }
                    requesterName = travel.Data.ClientName;
                    requesterEmail = travel.Data.Email;
                    break;
                case "DOMESTIC":
                    var domestic = await _quoteRequestRepository.GetDomesticDetailAsync(quoteRequestId);
                    if (domestic.Data is null)
                    {
                        _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: DOMESTIC detail not found.");
                        return;
                    }
                    // Domestic has no real client-name field yet (details_json
                    // is still a placeholder - see CreateDomesticQuoteRequest's
                    // own comment) - IdNo is the closest stand-in, same choice
                    // CreateDomestic makes for the "quote received" email.
                    requesterName = domestic.Data.IdNo;
                    requesterEmail = domestic.Data.Email;
                    break;
                default:
                    _logger.LogError($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: unrecognized product_code '{parentResult.Data.ProductCode}'.");
                    return;
            }

            if (string.IsNullOrWhiteSpace(requesterEmail))
            {
                _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: requester has no email on file.");
                return;
            }

            var offersResult = await _quoteOfferRepository.GetListByRequestAsync(quoteRequestId);
            if (!offersResult.IsSuccess || offersResult.Data is null || offersResult.Data.Count == 0)
            {
                _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: no offers found.");
                return;
            }

            var activeOffers = offersResult.Data.Where(o => o.Status == "ACTIVE").ToList();
            if (activeOffers.Count == 0)
            {
                _logger.LogWarn($"Offers-comparison email skipped for quote_request_id={quoteRequestId}: no ACTIVE offers to compare.");
                return;
            }

            // Documents are resolved through IQuoteOfferDocumentStorage, which
            // reads from the SAME shared folder (QuoteOffersStorage:Root) the
            // files were uploaded into - no wwwroot involved anymore.

            // Scapi's own mail-sending process (REMAILSERVICE's Worker.cs)
            // does NOT accept file content in the request - it reads the
            // "attachment" field as a file path and opens that path
            // directly off whatever disk IT is running on
            // (`new Attachment(path, ...)`). So every offer document has to
            // be copied from OUR shared storage folder into a folder Scapi's
            // process can also see, before we send the email request.
            // ScapiGateway:OffersAttachmentPath is that folder - set to
            // /root/scapi/offersfiles once this API is published onto the
            // same Ubuntu box Scapi runs on. Falls back to a local folder
            // under this project's own content root when that key is unset
            // (e.g. running on your Windows machine, where a Linux path like
            // /root/scapi/offersfiles wouldn't resolve to anything real
            // anyway).
            var offersAttachmentDir = _configuration["ScapiGateway:OffersAttachmentPath"];
            if (string.IsNullOrWhiteSpace(offersAttachmentDir))
            {
                offersAttachmentDir = Path.Combine(_env.ContentRootPath, "uploads", "scapi-offers-files");
            }
            Directory.CreateDirectory(offersAttachmentDir);

            var attachments = new List<QuoteOfferEmailAttachment>();

            foreach (var offer in activeOffers)
            {
                var attachment = new QuoteOfferEmailAttachment
                {
                    UnderwriterName = offer.UnderwriterName,
                    PremiumAmount = offer.PremiumAmount
                };

                if (!string.IsNullOrWhiteSpace(offer.DocumentPath))
                {
                    try
                    {
                        await using var sourceStream = await _documentStorage.OpenAsync(offer.DocumentPath);

                        if (sourceStream is not null)
                        {
                            var fileName = _documentStorage.GetFileName(offer.DocumentPath)!;
                            attachment.DocumentFileName = fileName;

                            // Copy (not move) - the original stays in the
                            // shared storage folder, since that's still
                            // where the authenticated download endpoint
                            // reads it back from. The upload-time filename
                            // is already a GUID (see LocalQuoteOfferDocumentStorage),
                            // so there's no collision risk copying it under
                            // the same name here; overwrite:true just makes
                            // a resend safe.
                            var destPath = Path.Combine(offersAttachmentDir, fileName);
                            await using (var destStream = new FileStream(destPath, FileMode.Create))
                            {
                                await sourceStream.CopyToAsync(destStream);
                            }
                            attachment.ScapiAttachmentPath = destPath;
                        }
                        else
                        {
                            _logger.LogWarn($"Offers-comparison email: document file missing on disk for quote_offer_id={offer.QuoteOfferId}, path={offer.DocumentPath}.");
                        }
                    }
                    catch (Exception ex)
                    {
                        // A missing/unreadable/uncopyable document shouldn't
                        // drop the whole offer out of the comparison email -
                        // it just goes out without its attachment.
                        _logger.LogError($"Offers-comparison email: failed copying document for quote_offer_id={offer.QuoteOfferId}, path={offer.DocumentPath}.", ex);
                    }
                }

                attachments.Add(attachment);
            }

            var refNo = parentResult.Data.RefNo ?? quoteRequestId.ToString();
            var externalRef = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
            var sent = await _notificationSender.SendOffersComparisonEmailAsync(requesterEmail, requesterName, refNo, attachments, externalRef);

            if (!sent)
            {
                _logger.LogWarn($"Offers-comparison email failed to send for quote_request_id={quoteRequestId}, ref_no={refNo}.");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError($"Offers-comparison email threw for quote_request_id={quoteRequestId}.", ex);
        }
    }

    /// <summary>Resolves the audit actor_type/actor_id/requested_by_user_id for the current caller's role.</summary>
    // CLIENT/CHANNEL_SERVICE callers are self-service, so requested_by_user_id
    // stays null (that field specifically means "staff acting on someone
    // else's behalf" per the schema design doc). Staff (USER) callers always
    // populate it with their own id.
    private (string ActorType, long ActorId, long? RequestedByUserId) ResolveActor()
    {
        return CurrentRoleCode switch
        {
            RoleCodes.Client => ("CLIENT", CurrentUserId, null),
            RoleCodes.ChannelService => ("CHANNEL_SERVICE", CurrentUserId, null),
            _ => ("USER", CurrentUserId, CurrentUserId)
        };
    }

    /// <summary>True if the caller is allowed to act on/see a quote request tied to this client_id.</summary>
    // Staff and channel-service callers aren't restricted here. A
    // Client-role caller must supply a client_id, and it must resolve
    // (via IClientRepository, same lookup VehiclesController uses) to a
    // Client record whose user_id is their own - a null client_id or a
    // mismatch both fail closed.
    private async Task<bool> CallerOwnsClientRecordAsync(long? clientId)
    {
        if (CurrentRoleCode != RoleCodes.Client)
        {
            return true;
        }

        if (clientId is null)
        {
            return false;
        }

        var clientResult = await _clientRepository.GetByIdAsync(clientId.Value);
        return clientResult.IsSuccess && clientResult.Data?.UserId == CurrentUserId;
    }
}
