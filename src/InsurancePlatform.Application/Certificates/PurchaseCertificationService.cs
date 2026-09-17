using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Certificates;

/// <summary>
/// The single completion path every certificate trigger - the M-Pesa
/// callback (MpesaCallbackController), the staff retry button
/// (PurchasesController.CompleteCert) and the background take-over worker
/// (PurchaseCertCompletionWorker) - funnels through. Runs the shared
/// usp_Purchase_CompleteCert locally-generated certificate step, then
/// (when Dmvic:Enabled) a best-effort NTSA official certificate issuance
/// that falls back to the already-generated internal certificate on any
/// failure. Keeping this in one service guarantees the official-cert
/// behaviour never drifts between the three trigger points.
/// </summary>
public class PurchaseCertificationService : IPurchaseCertificationService
{
    private readonly IPurchaseRepository _purchaseRepository;
    private readonly IDmvicCertificateService _dmvicCertificateService;
    private readonly DmvicOptions _options;
    private readonly ILoggerManager _logger;

    public PurchaseCertificationService(
        IPurchaseRepository purchaseRepository,
        IDmvicCertificateService dmvicCertificateService,
        IConfiguration configuration,
        ILoggerManager logger)
    {
        _purchaseRepository = purchaseRepository;
        _dmvicCertificateService = dmvicCertificateService;
        _options = configuration.GetSection("Dmvic").Get<DmvicOptions>() ?? new DmvicOptions();
        _logger = logger;
    }

    public async Task<StoredProcResult> CompleteAndIssueAsync(long purchaseId, string actorType, long actorId)
    {
        // 1. Internal certificate (shared usp_Purchase_CompleteCert routine,
        //    idempotent - the three callers retry safely).
        var completed = await _purchaseRepository.CompleteCertAsync(purchaseId, actorType, actorId);

        // 2. Best-effort NTSA issuance - never blocks or fails the purchase.
        //    Any exception is caught so a SCAPI outage (workers down, etc.)
        //    cannot break the callback/retry/worker paths.
        if (completed.IsSuccess && _options.Enabled)
        {
            try
            {
                var issue = await _dmvicCertificateService.IssueForPurchaseAsync(purchaseId);
                if (issue.Issued)
                {
                    _logger.LogInfo(
                        $"Official NTSA certificate issued for purchase_id={purchaseId}: {issue.CertificateNo} (transaction {issue.TransactionNo}).");
                }
                else
                {
                    _logger.LogWarn(
                        $"Official NTSA certificate skipped for purchase_id={purchaseId} (internal certificate kept): {issue.Message}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    $"Official NTSA certificate issuance failed for purchase_id={purchaseId}; keeping internal certificate.", ex);
            }
        }

        return completed;
    }
}