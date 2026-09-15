using System.Text.Json;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Domain.Common;
using Microsoft.AspNetCore.Authorization;

namespace InsurancePlatform.Api.Middleware;

/// <summary>
/// Enforces that a token can only be used from the same channel it was
/// issued for - a token minted with "channel": "PORTAL" (see
/// JwtTokenService) gets rejected if the request presenting it declares
/// X-Channel: MOBILE, even for the exact same user or the exact same
/// role. This applies uniformly to every authenticated caller - Client,
/// Agent, AgentAdmin, SupportAgent, SuperAdmin, and channel-service
/// (USSD/WhatsApp) tokens alike.
///
/// Placement: registered AFTER UseAuthentication (so HttpContext.User is
/// already populated from a validated token by the time this runs) and
/// BEFORE UseAuthorization (so a channel mismatch short-circuits with a
/// clean 401 before any policy/role check even gets evaluated).
///
/// [AllowAnonymous] endpoints are skipped even if the caller happens to
/// attach a valid-but-mismatched token to them - UseAuthentication runs
/// unconditionally for every request regardless of [AllowAnonymous], so
/// without this check a public endpoint like GET /api/products could
/// reject a request over something that endpoint doesn't even care about.
/// </summary>
public class ChannelBindingMiddleware
{
    private const string HeaderName = "X-Channel";

    private readonly RequestDelegate _next;

    public ChannelBindingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ILoggerManager logger, CorrelationContext correlationContext)
    {
        var allowsAnonymous = context.GetEndpoint()?.Metadata.GetMetadata<IAllowAnonymous>() != null;

        if (!allowsAnonymous && context.User.Identity?.IsAuthenticated == true)
        {
            var tokenChannel = context.User.FindFirst("channel")?.Value;
            var requestChannel = context.Request.Headers.TryGetValue(HeaderName, out var headerValue) ? headerValue.ToString() : null;

            if (string.IsNullOrEmpty(tokenChannel) ||
                string.IsNullOrEmpty(requestChannel) ||
                !string.Equals(tokenChannel, requestChannel, StringComparison.OrdinalIgnoreCase))
            {
                logger.LogWarn($"Channel binding rejected (ref={correlationContext.Ref}): token channel={tokenChannel ?? "(none)"}, request {HeaderName}={requestChannel ?? "(missing)"}.");

                context.Response.ContentType = "application/json";
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;

                var response = ApiResponse<object?>.Fail(
                    "This token was issued for a different channel and cannot be used here.",
                    correlationContext.Ref);

                await context.Response.WriteAsync(JsonSerializer.Serialize(response));
                return;
            }
        }

        await _next(context);
    }
}
