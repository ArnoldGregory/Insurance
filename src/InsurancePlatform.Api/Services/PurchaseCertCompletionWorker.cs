using InsurancePlatform.Application.Certificates;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Options;

namespace InsurancePlatform.Api.Services;

/// <summary>
/// Background take-over service for certificate completion. Polls
/// usp_Purchase_FindPendingCertCompletion (every purchase whose payment is
/// confirmed PAID but whose certificate isn't generated yet) and loops each
/// purchase_id through the shared IPurchaseCertificationService - the exact
/// same routine the staff "retry cert" button and the M-Pesa callback call,
/// so completion logic (internal certificate + best-effort NTSA issuance)
/// stays in one place (see usp_Purchase_CompleteCert's own doc comment).
///
/// Registered behind the "PurchaseCompletionWorker" config section so it can
/// be switched off (or its poll interval tuned) without a rebuild. It has no
/// request context, so it creates its own DI scope per poll and resolves the
/// scoped repository implementations fresh - repositories hold no per-scope
/// state beyond the executor, so this is safe.
/// </summary>
public class PurchaseCertCompletionWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILoggerManager _logger;
    private readonly PurchaseCompletionWorkerOptions _options;

    public PurchaseCertCompletionWorker(
        IServiceScopeFactory scopeFactory,
        ILoggerManager logger,
        IOptions<PurchaseCompletionWorkerOptions> options)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _options = options.Value;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInfo(
            $"PurchaseCertCompletionWorker started (interval={_options.IntervalSeconds}s). Polling for PAID purchases awaiting certificate generation.");

        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(_options.IntervalSeconds));

        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    await RunPollAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    // One bad poll must never kill the whole loop - log, then
                    // let the next interval try again (same philosophy as the
                    // BIMADLINE PURCHASESERVICE worker's outer try/catch).
                    _logger.LogError(
                        $"PurchaseCertCompletionWorker poll failed (will retry next interval): {ex.Message}",
                        ex);
                }
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Normal shutdown - the loop exits via WaitForNextTickAsync.
        }

        _logger.LogInfo("PurchaseCertCompletionWorker stopped.");
    }

    private async Task RunPollAsync(CancellationToken stoppingToken)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var purchaseRepository = scope.ServiceProvider.GetRequiredService<IPurchaseRepository>();
        var certificationService = scope.ServiceProvider.GetRequiredService<IPurchaseCertificationService>();

        var pending = await purchaseRepository.FindPendingCertCompletionAsync();

        if (!pending.IsSuccess)
        {
            _logger.LogWarn(
                $"PurchaseCertCompletionWorker could not list pending purchases: {pending.ResultMessage}");
            return;
        }

        var pendingIds = pending.Data ?? new List<long>();
        if (pendingIds.Count == 0)
        {
            return;
        }

        _logger.LogInfo(
            $"PurchaseCertCompletionWorker found {pendingIds.Count} purchase(s) awaiting certificate completion.");

        foreach (var purchaseId in pendingIds)
        {
            stoppingToken.ThrowIfCancellationRequested();

            var completed = await certificationService.CompleteAndIssueAsync(
                purchaseId, "PURCHASE_WORKER", purchaseId);

            if (completed.IsSuccess)
            {
                _logger.LogInfo(
                    $"PurchaseCertCompletionWorker completed certificate for purchase_id={purchaseId}.");
            }
            else
            {
                // usp_Purchase_CompleteCert returns a non-zero code for
                // not-PAID / already-GENERATED too, so a "failure" here is
                // often just a row that raced with the webhook path - not
                // something to alarm about. Logged as warn for visibility.
                _logger.LogWarn(
                    $"PurchaseCertCompletionWorker could not complete certificate for purchase_id={purchaseId}: {completed.ResultMessage}");
            }
        }
    }
}

/// <summary>
/// Config for PurchaseCertCompletionWorker - bound to the
/// "PurchaseCompletionWorker" appsettings.json section in Program.cs.
/// </summary>
public sealed class PurchaseCompletionWorkerOptions
{
    public int IntervalSeconds { get; set; } = 60;
}