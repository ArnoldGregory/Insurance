using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Payment attempts, always viewed in the context of one purchase - the API
/// has no "list every payment" endpoint (see PaymentContracts/
/// PaymentsController on the API side), only GET /api/payments/by-purchase/
/// {purchaseId}. Gated to RoleCodes.QuoteBackoffice (SA/AA/SP) matching
/// both the seeded Payments menu grant and the portal-relevant subset of
/// UpdateStatus's real [Authorize(Roles = CS,SA,AA,SP)] - ChannelService is
/// machine-to-machine and never signs into this portal.
/// </summary>
[Authorize(Roles = RoleCodes.QuoteBackoffice)]
public class PaymentsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public PaymentsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public IActionResult Index()
    {
        return View(new PaymentLookupViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Index(PaymentLookupViewModel model)
    {
        if (!ModelState.IsValid || model.PurchaseId is null)
        {
            return View(model);
        }

        return RedirectToAction(nameof(ForPurchase), new { purchaseId = model.PurchaseId.Value });
    }

    [HttpGet]
    public async Task<IActionResult> ForPurchase(long purchaseId)
    {
        var result = await _apiClient.GetAsync<List<PaymentItem>>($"/api/payments/by-purchase/{purchaseId}");

        var vm = new PaymentsForPurchaseViewModel
        {
            PurchaseId = purchaseId,
            Items = result.Success ? result.Data ?? new List<PaymentItem>() : new List<PaymentItem>(),
            CanUpdateStatus = true, // class-level [Authorize(Roles=QuoteBackoffice)] already guarantees this for anyone who reached this action
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        if (!result.Success)
        {
            vm.StatusMessage = result.Message;
            vm.StatusIsError = true;
        }

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(PaymentStatusUpdateViewModel model)
    {
        if (!ModelState.IsValid || string.IsNullOrWhiteSpace(model.Status))
        {
            TempData["StatusMessage"] = "Pick a status.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(ForPurchase), new { purchaseId = model.PurchaseId });
        }

        var result = await _apiClient.PutAsync<object>($"/api/payments/{model.PaymentId}/status", new
        {
            Status = model.Status,
            TransactionReference = model.TransactionReference
        });

        // On SUCCESS this also flips the parent Purchase's payment_status
        // to PAID server-side (usp_Payment_UpdateStatus's own doc comment) -
        // nothing more to do here, the Purchases screen will show it
        // correctly next time it's loaded.
        TempData["StatusMessage"] = result.Success ? $"Payment #{model.PaymentId} marked {model.Status}." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(ForPurchase), new { purchaseId = model.PurchaseId });
    }
}
