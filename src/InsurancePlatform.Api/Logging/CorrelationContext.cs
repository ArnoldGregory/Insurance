namespace InsurancePlatform.Api.Logging;

/// <summary>
/// Registered Scoped in DI (Program.cs), so exactly one instance exists per
/// HTTP request, shared by every class that requests it for that request.
/// CorrelationMiddleware sets Ref once, at the very start of the request.
///
/// This class is NOT what makes the ref show up in log lines — that's
/// NLog.ScopeContext, pushed separately in CorrelationMiddleware, which
/// every log call picks up automatically via NLog.config's
/// ${scopeproperty:item=Ref}, with no injection needed anywhere.
///
/// This class exists for the smaller number of cases where code needs to
/// read the current ref as a value — e.g. to include it in an error response
/// body ("quote this reference if you contact support"), or to forward it as
/// an outgoing X-Correlation-Id header when this API calls another of our
/// own services.
/// </summary>
public class CorrelationContext
{
    public string Ref { get; set; } = "REQ-UNSET";
}
