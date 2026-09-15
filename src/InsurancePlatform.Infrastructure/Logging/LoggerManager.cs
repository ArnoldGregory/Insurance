using InsurancePlatform.Domain.Common;
using NLog;

namespace InsurancePlatform.Infrastructure.Logging;

/// <summary>
/// The only class in the solution that calls NLog's logging API directly.
/// Application services and Data repositories depend on ILoggerManager
/// (defined in Domain.Common, no NLog in sight) and get this implementation
/// injected at runtime - wired up in Api's Program.cs as
/// AddScoped&lt;ILoggerManager, LoggerManager&gt;(). Moved here from Api so
/// that any future non-web consumer (a background worker, a console job)
/// could reuse it without needing to reference the Api project at all.
///
/// Deliberately does NOT prepend the correlation ref to the message string.
/// The ref is already attached to every log line via NLog.ScopeContext
/// (pushed once per request by Api's CorrelationMiddleware, which - unlike
/// this class - genuinely is HTTP-specific and stays in Api) and
/// NLog.config's layout. That happens automatically for any code that logs
/// during a request, including code that has never heard of a correlation
/// ref and never will.
/// </summary>
public class LoggerManager : ILoggerManager
{
    private static readonly Logger logger = LogManager.GetCurrentClassLogger();

    public void LogDebug(string message) => logger.Debug(message);

    public void LogInfo(string message) => logger.Info(message);

    public void LogWarn(string message) => logger.Warn(message);

    public void LogError(string message) => logger.Error(message);

    public void LogError(string message, Exception exception) => logger.Error(exception, message);
}
