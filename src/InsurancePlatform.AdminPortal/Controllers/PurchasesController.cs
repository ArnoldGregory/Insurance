using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Purchase browsing + status changes, mirroring InsurancePlatform.Api's
/// PurchasesController. Class-level [Authorize(Roles = AllStaff)] matches
/// GetList's own [Authorize(Roles=SA,AA,AG,SP)] - an Agent can browse (and
/// the API itself scopes their view to purchases they personally executed,
/// same as Clients). UpdateStatus then layers a second, narrower
/// [Authorize(Roles = QuoteBackoffice)] (SA,AA,SP - Agent excluded), same
/// stacking approach as ClientsController's Create/Edit. Purchase creation
/// itself (buying a policy) isn't part of this screen - that's a real
/// point-of-sale flow (product/pricing/vehicle/quote-offer selection) that
/// deserves its own dedicated build, not bolted onto a browsing screen.
/// </summary>
[Authorize(Roles = RoleCodes.AllStaff)]
public class PurchasesController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public PurchasesController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? status, string? paymentStatus, int pageNumber = 1, int pageSize = 20)
    {
        pageNumber = pageNumber < 1 ? 1 : pageNumber;
        pageSize = pageSize is < 1 or > 200 ? 20 : pageSize;

        var query = $"/api/purchases?pageNumber={pageNumber}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(status))
        {
            query += $"&status={Uri.EscapeDataString(status)}";
        }
        if (!string.IsNullOrWhiteSpace(paymentStatus))
        {
            query += $"&paymentStatus={Uri.EscapeDataString(paymentStatus)}";
        }

        var result = await _apiClient.GetAsync<PurchaseListPage>(query);
        var page = result.Success ? result.Data ?? new PurchaseListPage() : new PurchaseListPage();

        var roleCode = User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;

        var vm = new PurchaseIndexViewModel
        {
            Items = page.Items,
            TotalCount = page.TotalCount,
            Status = status,
            PaymentStatus = paymentStatus,
            PageNumber = pageNumber,
            PageSize = pageSize,
            CanChangeStatus = RoleCodes.QuoteBackoffice.Split(',').Contains(roleCode),
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

    [HttpGet]
    public async Task<IActionResult> Details(long id)
    {
        var result = await _apiClient.GetAsync<PurchaseDetail>($"/api/purchases/{id}");

        if (!result.Success || result.Data is null)
        {
            TempData["StatusMessage"] = result.Message;
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var roleCode = User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;
        ViewData["CanChangeStatus"] = RoleCodes.QuoteBackoffice.Split(',').Contains(roleCode);
        ViewData["StatusMessage"] = TempData["StatusMessage"] as string;
        ViewData["StatusIsError"] = TempData["StatusIsError"] is true;

        return View(result.Data);
    }

    /// <summary>Shows the stored official NTSA certificate document (raw get_certificate payload) for a purchase that got one issued.</summary>
    [HttpGet("NtsaDocument/{id}")]
    public async Task<IActionResult> NtsaDocument(long id)
    {
        var result = await _apiClient.GetAsync<VehicleCertificateDocumentModel>($"/api/purchases/{id}/ntsa-certificate");

        if (!result.Success || result.Data is null)
        {
            TempData["StatusMessage"] = result.Message ?? "No official NTSA certificate document for this purchase.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id });
        }

        return View(result.Data);
    }

    [Authorize(Roles = RoleCodes.QuoteBackoffice)]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(PurchaseStatusUpdateViewModel model)
    {
        if (!ModelState.IsValid || string.IsNullOrWhiteSpace(model.Status))
        {
            TempData["StatusMessage"] = "Pick a status.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id = model.PurchaseId });
        }

        var result = await _apiClient.PutAsync<object>($"/api/purchases/{model.PurchaseId}/status", new { Status = model.Status });

        TempData["StatusMessage"] = result.Success ? $"Purchase status changed to {model.Status}." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.PurchaseId });
    }

    [HttpGet("Journey/{id}")]
    public async Task<IActionResult> Journey(long id)
    {
        var result = await _apiClient.GetAsync<List<PurchaseTimelineEventModel>>($"/api/pricing/purchases/{id}/journey");
        if (!result.Success || result.Data == null)
        {
            TempData["StatusMessage"] = result.Message ?? "Could not load purchase journey.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var events = result.Data;
        var vm = new PurchaseJourneyViewModel { PurchaseId = id, Timeline = events };

        var summaryEvent = events.FirstOrDefault(e => e.EventType == "PURCHASE_SUMMARY");
        if (summaryEvent != null)
        {
            var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(summaryEvent.EventDataJson) ?? new();
            vm.Summary = new PurchaseSummaryModel
            {
                PolicyNumber = dict.GetString("policy_number"),
                PremiumAmount = dict.GetDecimal("premium_amount"),
                PaymentStatus = dict.GetString("payment_status"),
                Status = dict.GetString("status"),
                ClientName = dict.GetString("client_name"),
                ClientIdNo = dict.GetString("client_id_no"),
                ClientPhone = dict.GetString("client_phone"),
                ClientEmail = dict.GetString("client_email"),
                ProductName = dict.GetString("product_name"),
                ProductCode = dict.GetString("product_code"),
                UnderwriterName = dict.GetString("underwriter_name"),
                CreatedByName = dict.GetString("created_by_name"),
                CreatedOn = summaryEvent.EventTime,
                StartDate = dict.GetNullableDate("start_date"),
                EndDate = dict.GetNullableDate("end_date"),
                CertificateStatus = dict.GetString("certificate_status"),
                CertificateNumber = dict.GetString("certificate_number"),
                CertificateGeneratedOn = dict.GetNullableDate("cert_generated_on")
            };
        }

        vm.Payments = events.Where(e => e.StepOrder == 2).Select(e =>
        {
            var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(e.EventDataJson) ?? new();
            return new PurchasePaymentModel
            {
                PaymentId = e.RefId,
                Amount = dict.GetDecimal("amount"),
                Method = dict.GetString("method"),
                PayerPhone = dict.GetString("payer_phone"),
                TransactionReference = dict.GetString("transaction_reference"),
                Status = dict.GetString("status") ?? e.EventType,
                InitiatedOn = e.EventTime,
                CompletedOn = dict.GetNullableDate("completed_on")
            };
        }).ToList();

        var vehicleEvent = events.FirstOrDefault(e => e.EventType == "VEHICLE");
        if (vehicleEvent != null)
        {
            var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(vehicleEvent.EventDataJson) ?? new();
            vm.Vehicle = new PurchaseVehicleModel
            {
                VehicleValue = dict.GetNullableDecimal("vehicle_value"),
                Make = dict.GetString("make"),
                Model = dict.GetString("model"),
                RegNo = dict.GetString("reg_no"),
                ChassisNo = dict.GetString("chassis_no"),
                YearOfManufacture = dict.GetNullableInt("yearofmanufacture")
            };
        }

        vm.RelatedPurchases = events.Where(e => e.EventType == "RELATED_PURCHASE").Select(e =>
        {
            var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(e.EventDataJson) ?? new();
            return new PurchaseRelatedModel
            {
                PurchaseId = dict.GetLong("purchase_id"),
                PolicyNumber = dict.GetString("policy_number"),
                PremiumAmount = dict.GetDecimal("premium_amount"),
                PaymentStatus = dict.GetString("payment_status"),
                Status = dict.GetString("status"),
                CreatedOn = e.EventTime,
                UnderwriterName = dict.GetString("underwriter_name")
            };
        }).ToList();

        return View(vm);
    }

    /// <summary>Printable certificate for a PAID purchase whose certificate has been generated.</summary>
    [HttpGet("Certificate/{id}")]
    public async Task<IActionResult> Certificate(long id)
    {
        var result = await _apiClient.GetAsync<PurchaseDetail>($"/api/purchases/{id}");

        if (!result.Success || result.Data is null)
        {
            TempData["StatusMessage"] = result.Message ?? "Could not load purchase.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var purchase = result.Data;
        if (purchase.PaymentStatus != "PAID" || purchase.CertificateStatus != "GENERATED")
        {
            TempData["StatusMessage"] = "The certificate is only available once the payment is confirmed and the certificate has been generated.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Journey), new { id });
        }

        return View(purchase);
    }
}

internal static class JsonDictExtensions
{
    private static object? Unwrap(object? v) => v switch
    {
        System.Text.Json.JsonElement je => je.ValueKind switch
        {
            System.Text.Json.JsonValueKind.String => je.GetString(),
            System.Text.Json.JsonValueKind.Number => je.GetRawText(),
            System.Text.Json.JsonValueKind.True => true,
            System.Text.Json.JsonValueKind.False => false,
            System.Text.Json.JsonValueKind.Null => null,
            _ => je.GetRawText()
        },
        _ => v
    };

    public static string GetString(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) ? Unwrap(v)?.ToString() ?? "" : "";
    public static decimal GetDecimal(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) && Unwrap(v) is { } u ? Convert.ToDecimal(u) : 0;
    public static long GetLong(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) && Unwrap(v) is { } u ? Convert.ToInt64(u) : 0;
    public static int? GetNullableInt(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) && Unwrap(v) is { } u ? Convert.ToInt32(u) : null;
    public static decimal? GetNullableDecimal(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) && Unwrap(v) is { } u ? Convert.ToDecimal(u) : null;
    public static DateTime? GetNullableDate(this Dictionary<string, object> d, string key) => d.TryGetValue(key, out var v) && Unwrap(v) is { } u ? Convert.ToDateTime(u.ToString()) : null;
}
