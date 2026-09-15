using System.Text.Json;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Api.Middleware;

/// <summary>
/// Registered first in the pipeline (before CorrelationMiddleware) - it
/// needs to wrap literally everything else, since an unhandled exception can
/// come from any later stage, including authentication/authorization
/// middleware. Without this, an unhandled exception would fall through to
/// ASP.NET Core's default behavior (a bare, unformatted error response),
/// breaking the "every response looks like ApiResponse&lt;T&gt;" promise the
/// moment something actually throws.
///
/// Placement note: even though this runs before CorrelationMiddleware,
/// CorrelationContext.Ref is still populated correctly here when an
/// exception is caught - because exceptions bubble UP through the pipeline.
/// By the time an exception thrown deep in a controller reaches this
/// catch block, CorrelationMiddleware already ran and set Ref earlier in
/// this same request.
/// </summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ExceptionHandlingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ILoggerManager logger, CorrelationContext correlationContext)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            logger.LogError($"Unhandled exception (ref={correlationContext.Ref}).", ex);

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;

            var response = ApiResponse<object?>.Fail(
                "An unexpected error occurred. Please try again or contact support with this reference.",
                correlationContext.Ref);

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
    }
}
