using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Certificates;
using InsurancePlatform.Domain.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>
/// Endpoints insurers (or SCAPI on their behalf) POST to when a certificate
/// they issue on their side is ready - the equivalents of BIMADLINE's
/// api/BimaDLine/DirectLineRequest, AmacoRequest and DefiniteCallback.
/// Payload shapes match what those insurers send BIMADLINE today.
///
/// Like the M-Pesa callbacks these are [AllowAnonymous]: the insurer can't
/// log in. A callback is only ever matched to a request WE opened (by our
/// external reference, or for AMACO the policy number), so an unknown
/// reference changes nothing. When UnderwriterIntegrations:CallbackSecret is
/// set, the X-Callback-Key header must match it. Every call is logged with
/// the source IP and full body, and always answered 200 so senders stop retrying.
/// </summary>
[ApiController]
[Route("api/underwriter-callbacks")]
[AllowAnonymous]
public class UnderwriterCallbacksController : BaseApiController
{
    private const string SecretHeader = "X-Callback-Key";

    private readonly IUnderwriterCertificateService _underwriterCertificateService;
    private readonly UnderwriterIntegrationOptions _options;
    private readonly ILoggerManager _logger;

    public UnderwriterCallbacksController(
        IUnderwriterCertificateService underwriterCertificateService,
        IConfiguration configuration,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _underwriterCertificateService = underwriterCertificateService;
        _options = configuration.GetSection(UnderwriterIntegrationOptions.SectionName).Get<UnderwriterIntegrationOptions>()
                   ?? new UnderwriterIntegrationOptions();
        _logger = logger;
    }

    /// <summary>
    /// DirectLine certificate callback. Body:
    /// { "transaction_code": "&lt;our ref&gt;", "policy_number": "...", "cert_number": "...", "certDownloadUrl": "https://..." }
    /// </summary>
    [HttpPost("directline")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public Task<IActionResult> DirectLine([FromBody] JsonObject? body) =>
        HandleAsync(UnderwriterIntegrations.DirectLine, body, json =>
        {
            var certNo = Text(json, "cert_number");
            return new UnderwriterCallback
            {
                Integration = UnderwriterIntegrations.DirectLine,
                ExternalRef = Text(json, "transaction_code"),
                PolicyNumber = Text(json, "policy_number"),
                CertificateNo = certNo,
                CertificateUrl = Text(json, "certDownloadUrl"),
                Success = !string.IsNullOrWhiteSpace(certNo),
                ErrorMessage = Text(json, "message"),
                RawPayload = json.ToJsonString()
            };
        });

    /// <summary>
    /// Definite Assurance callback. Success:
    /// { "success": true, "certNo": "...", "certURL": "https://...", "ExternalRef": "&lt;our ref&gt;", "message": "..." }
    /// Failure: { "success": false, "message": "...", "errorMessage": "...", "ExternalRef": "..." }
    /// </summary>
    [HttpPost("definite")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public Task<IActionResult> Definite([FromBody] JsonObject? body) =>
        HandleAsync(UnderwriterIntegrations.Definite, body, json => new UnderwriterCallback
        {
            Integration = UnderwriterIntegrations.Definite,
            ExternalRef = Text(json, "ExternalRef") ?? Text(json, "externalRef"),
            PolicyNumber = Text(json, "policyNo") ?? Text(json, "PolicyNumber"),
            Success = IsTrue(json["success"]),
            CertificateNo = Text(json, "certNo"),
            CertificateUrl = Text(json, "certURL"),
            ErrorMessage = Text(json, "errorMessage") ?? Text(json, "message"),
            RawPayload = json.ToJsonString()
        });

    /// <summary>
    /// AMACO callback. Body:
    /// { "success": true, "contents": { "CertificateNumber": "...", "CertificateURL": "https://...", "PolicyNumber": "...", "EndorsementNumber": "..." } }
    /// AMACO doesn't echo our reference, so the request is matched on PolicyNumber
    /// (an "ExternalRef" field is used first if they ever send one).
    /// </summary>
    [HttpPost("amaco")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public Task<IActionResult> Amaco([FromBody] JsonObject? body) =>
        HandleAsync(UnderwriterIntegrations.Amaco, body, json =>
        {
            var contents = json["contents"] as JsonObject;
            return new UnderwriterCallback
            {
                Integration = UnderwriterIntegrations.Amaco,
                ExternalRef = Text(json, "ExternalRef") ?? (contents is null ? null : Text(contents, "ExternalRef")),
                PolicyNumber = contents is null ? null : Text(contents, "PolicyNumber"),
                Success = IsTrue(json["success"]),
                CertificateNo = contents is null ? null : Text(contents, "CertificateNumber"),
                CertificateUrl = contents is null ? null : Text(contents, "CertificateURL"),
                ErrorMessage = Text(json, "message") ?? Text(json, "errorMessage"),
                RawPayload = json.ToJsonString()
            };
        });

    private async Task<IActionResult> HandleAsync(string integration, JsonObject? body, Func<JsonObject, UnderwriterCallback> map)
    {
        var sourceIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        _logger.LogInfo($"{integration} certificate callback from {sourceIp} (ref={CorrelationRef}): {body?.ToJsonString() ?? "(empty body)"}");

        if (!SecretMatches())
        {
            _logger.LogWarn($"{integration} certificate callback from {sourceIp} rejected: missing/wrong {SecretHeader}.");
            return Unauthorized(ApiResponse<object?>.Fail("Invalid callback key.", CorrelationRef));
        }

        if (body is null)
        {
            return Ok(ApiResponse<object?>.Fail("Empty callback body.", CorrelationRef));
        }

        try
        {
            var result = await _underwriterCertificateService.CompleteFromCallbackAsync(map(body));
            return Ok(result.Accepted
                ? ApiResponse<object?>.Ok(new { result.PurchaseId }, result.Message, CorrelationRef)
                : ApiResponse<object?>.Fail(result.Message, CorrelationRef));
        }
        catch (Exception ex)
        {
            _logger.LogError($"{integration} certificate callback (ref={CorrelationRef}) failed.", ex);
            return Ok(ApiResponse<object?>.Fail("Callback could not be processed.", CorrelationRef));
        }
    }

    private bool SecretMatches()
    {
        if (string.IsNullOrEmpty(_options.CallbackSecret))
        {
            return true;
        }

        var supplied = Request.Headers.TryGetValue(SecretHeader, out var value) ? value.ToString() : string.Empty;
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(supplied), Encoding.UTF8.GetBytes(_options.CallbackSecret));
    }

    private static string? Text(JsonObject json, string name)
    {
        var value = json[name]?.ToString()?.Trim();
        return string.IsNullOrEmpty(value) ? null : value;
    }

    private static bool IsTrue(JsonNode? node) =>
        node?.ToString() is { } text && text.Equals("true", StringComparison.OrdinalIgnoreCase);
}
