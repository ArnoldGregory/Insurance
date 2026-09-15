using InsurancePlatform.Api.Logging;

namespace InsurancePlatform.Api.Middleware;

public class CorrelationMiddleware
{
    private const string HeaderName = "X-Correlation-Id";

    private readonly RequestDelegate _next;

    public CorrelationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, CorrelationContext correlationContext)
    {
        var reference = context.Request.Headers.TryGetValue(HeaderName, out var incoming) && !string.IsNullOrWhiteSpace(incoming) ? incoming.ToString() : GenerateReference();

        correlationContext.Ref = reference;
        context.Response.Headers[HeaderName] = reference;

        using (NLog.ScopeContext.PushProperty("Ref", reference))
        {
            await _next(context);
        }
    }

    private static string GenerateReference()
    {
        var timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
        var suffix = Guid.NewGuid().ToString("N")[..6];
        return $"REQ-{timestamp}-{suffix}";
    }
}
