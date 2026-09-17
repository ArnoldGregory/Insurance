using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The back-office quote work queue - mirrors InsurancePlatform.Api's
/// QuoteRequestsController's BackofficeRoles exactly (SA/AA/SP - see
/// RoleCodes.QuoteBackoffice). Agent never sees this screen (it isn't
/// even in Agent's granted menu tree) since "assigned_backoffice_user_id"
/// is explicitly a back-office concept on the API side, not something an
/// Agent manages - see that controller's own top-of-file comment.
///
/// "Assign to a specific person" only offers Support (SP) staff - not
/// every backoffice role - since Support is who actually works the quote
/// queue day to day; SuperAdmin/AgentAdmin can still self-assign via
/// "Assign to me" the same as before. That's why AssignableStaff below is
/// always fetched with roleCode=SP, never blank.
/// </summary>
[Authorize(Roles = RoleCodes.QuoteBackoffice)]
public class QuoteRequestsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public QuoteRequestsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? status, long? productId, bool mine = false)
    {
        const int pageNumber = 1;
        const int pageSize = 500;

        var query = $"/api/quoterequests?pageNumber={pageNumber}&pageSize={pageSize}";

        if (!string.IsNullOrWhiteSpace(status))
        {
            query += $"&status={Uri.EscapeDataString(status)}";
        }
        if (productId is not null)
        {
            query += $"&productId={productId.Value}";
        }
        // "mine" - the notification bell's "assigned to you" link lands here.
        // Not a persisted filter option in the dropdown UI, just a one-way
        // querystring flag that resolves the current caller's id and adds
        // the same assignedBackofficeUserId filter GetList already supports.
        if (mine)
        {
            var userIdRaw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (long.TryParse(userIdRaw, out var currentUserId))
            {
                query += $"&assignedBackofficeUserId={currentUserId}";
            }
        }

        // List + summary cards + the Support staff list (to resolve numeric
        // AssignedBackofficeUserId into a real name below) all load
        // independently - none of them depend on each other, so there's no
        // reason to await them one at a time.
        var listTask = _apiClient.GetAsync<QuoteRequestListPage>(query);
        var summaryTask = _apiClient.GetAsync<List<QuoteRequestProductSummary>>("/api/quoterequests/summary");
        var staffTask = GetAssignableStaffAsync();

        await Task.WhenAll(listTask, summaryTask, staffTask);

        var listResult = listTask.Result;
        var summaryResult = summaryTask.Result;
        var assignableStaff = staffTask.Result;

        var page = listResult.Success ? listResult.Data ?? new QuoteRequestListPage() : new QuoteRequestListPage();
        ResolveAssignedNames(page.Items, assignableStaff);

        var vm = new QuoteRequestIndexViewModel
        {
            Items = page.Items,
            TotalCount = page.TotalCount,
            Mine = mine,
            Status = status,
            ProductId = productId,
            PageNumber = pageNumber,
            PageSize = pageSize,
            Summary = summaryResult.Success ? summaryResult.Data ?? new() : new(),
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        if (!listResult.Success)
        {
            vm.StatusMessage = listResult.Message;
            vm.StatusIsError = true;
        }

        return View(vm);
    }

    [HttpGet]
    public async Task<IActionResult> Details(long id)
    {
        var parentResult = await _apiClient.GetAsync<QuoteRequestItem>($"/api/quoterequests/{id}");

        if (!parentResult.Success || parentResult.Data is null)
        {
            TempData["StatusMessage"] = parentResult.Message;
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        // Best-effort: a detail-shape lookup failing (unrecognized product,
        // or a genuinely empty detail row) shouldn't take down the whole
        // page - the parent row and offers are still useful on their own.
        var detailResult = await _apiClient.GetAsync<Dictionary<string, System.Text.Json.JsonElement>>($"/api/quoterequests/{id}/detail");
        var offersResult = await _apiClient.GetAsync<List<QuoteOfferItem>>($"/api/quoterequests/{id}/offers");
        var underwritersResult = await _apiClient.GetAsync<List<UnderwriterOption>>("/api/underwriters?activeOnly=true");
        var assignableStaff = await GetAssignableStaffAsync();

        ResolveAssignedNames(new[] { parentResult.Data }, assignableStaff);

        var offers = offersResult.Success ? offersResult.Data ?? new() : new List<QuoteOfferItem>();
        foreach (var offer in offers)
        {
            offer.DocumentUrl = BuildDocumentUrl(offer.QuoteOfferId);
        }

        var vm = new QuoteRequestDetailViewModel
        {
            Request = parentResult.Data,
            TypeDetail = detailResult.Success ? detailResult.Data ?? new() : new(),
            Offers = offers,
            UnderwriterOptions = underwritersResult.Success ? underwritersResult.Data ?? new() : new(),
            AssignableStaff = assignableStaff,
            StatusMessage = TempData["StatusMessage"] as string,
            StatusIsError = TempData["StatusIsError"] is true
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AssignToMe(long id)
    {
        var userIdRaw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!long.TryParse(userIdRaw, out var currentUserId))
        {
            TempData["StatusMessage"] = "Could not determine your user id from your session - please sign in again.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id });
        }

        var result = await _apiClient.PutAsync<object>($"/api/quoterequests/{id}/assign", new { AssignedBackofficeUserId = currentUserId });

        TempData["StatusMessage"] = result.Success ? "Assigned to you - now IN_PROGRESS." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id });
    }

    /// <summary>Admin picks a specific Support person from the dropdown, instead of "Assign to me".</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AssignToStaff(long id, long staffUserId)
    {
        var result = await _apiClient.PutAsync<object>($"/api/quoterequests/{id}/assign", new { AssignedBackofficeUserId = staffUserId });

        TempData["StatusMessage"] = result.Success ? "Assigned - now IN_PROGRESS." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Expire(long id)
    {
        var result = await _apiClient.PutAsync<object>($"/api/quoterequests/{id}/expire", new { });

        TempData["StatusMessage"] = result.Success ? "Quote request marked EXPIRED." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddOffer(CreateQuoteOfferViewModel model)
    {
        if (!ModelState.IsValid || model.UnderwriterId is null)
        {
            TempData["StatusMessage"] = "Pick an underwriter and enter a valid premium amount.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
        }

        var fields = new Dictionary<string, string>
        {
            ["UnderwriterId"] = model.UnderwriterId.Value.ToString(),
            ["PremiumAmount"] = model.PremiumAmount.ToString(System.Globalization.CultureInfo.InvariantCulture)
        };

        var result = await _apiClient.PostFormAsync<object>($"/api/quoterequests/{model.QuoteRequestId}/offers", model.Document, "Document", fields);

        TempData["StatusMessage"] = result.Success ? "Offer added - request moved to QUOTED." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
    }

    /// <summary>
    /// "Add offer(s)" modal's submit target - lets back office add several
    /// priced options in one go instead of one POST per offer (per the
    /// feature request: "add more than one offer then submit once"). Rows
    /// with no underwriter picked or a zero/blank premium are silently
    /// dropped (a person who clicked "Add another offer" but left it empty
    /// shouldn't get a validation error for it) - only rows with real data
    /// are sent on to the API's batch endpoint, which fires the client's
    /// "here are your options" comparison email once, after at least one
    /// row succeeds.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddOffersBatch(CreateQuoteOfferBatchViewModel model)
    {
        var validRows = (model.Offers ?? new()).Where(o => o.UnderwriterId is not null && o.PremiumAmount > 0).ToList();

        if (validRows.Count == 0)
        {
            TempData["StatusMessage"] = "Add at least one offer with an underwriter and a premium amount.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
        }

        var fields = new Dictionary<string, string>();
        var files = new Dictionary<string, IFormFile>();

        for (var i = 0; i < validRows.Count; i++)
        {
            fields[$"Offers[{i}].UnderwriterId"] = validRows[i].UnderwriterId!.Value.ToString();
            fields[$"Offers[{i}].PremiumAmount"] = validRows[i].PremiumAmount.ToString(System.Globalization.CultureInfo.InvariantCulture);

            if (validRows[i].Document is not null && validRows[i].Document!.Length > 0)
            {
                files[$"Offers[{i}].Document"] = validRows[i].Document!;
            }
        }

        var result = await _apiClient.PostMultiFormAsync<object>($"/api/quoterequests/{model.QuoteRequestId}/offers/batch", files, fields);

        TempData["StatusMessage"] = result.Success
            ? (validRows.Count == 1 ? "Offer added - request moved to QUOTED." : $"{validRows.Count} offers added - request moved to QUOTED.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
    }

    /// <summary>
    /// "Edit selected offer(s)" modal's submit target - the batch equivalent
    /// of EditOffer below, for correcting several ACTIVE offers on the same
    /// request in one submission ("even on edit" per the feature request).
    /// Works just as well for a single selected row as for several - there's
    /// no separate "batch of one" special case.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditOffersBatch(EditQuoteOfferBatchViewModel model)
    {
        var validRows = (model.Offers ?? new()).Where(o => o.QuoteOfferId > 0 && o.UnderwriterId is not null && o.PremiumAmount > 0).ToList();

        if (validRows.Count == 0)
        {
            TempData["StatusMessage"] = "Select at least one offer, with a valid underwriter and premium amount, to edit.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
        }

        var fields = new Dictionary<string, string> { ["QuoteRequestId"] = model.QuoteRequestId.ToString() };
        var files = new Dictionary<string, IFormFile>();

        for (var i = 0; i < validRows.Count; i++)
        {
            fields[$"Offers[{i}].QuoteOfferId"] = validRows[i].QuoteOfferId.ToString();
            fields[$"Offers[{i}].UnderwriterId"] = validRows[i].UnderwriterId!.Value.ToString();
            fields[$"Offers[{i}].PremiumAmount"] = validRows[i].PremiumAmount.ToString(System.Globalization.CultureInfo.InvariantCulture);

            if (validRows[i].Document is not null && validRows[i].Document!.Length > 0)
            {
                files[$"Offers[{i}].Document"] = validRows[i].Document!;
            }
        }

        var result = await _apiClient.PutMultiFormAsync<object>("/api/quote-offers/batch", files, fields);

        TempData["StatusMessage"] = result.Success
            ? (validRows.Count == 1 ? "Offer updated." : $"{validRows.Count} offers updated.")
            : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
    }

    /// <summary>
    /// GET form for editing an offer. There's no single "get one offer by
    /// id" API endpoint (only a list-by-request one) - rather than add one
    /// just to prefill this form, the current values travel here as query
    /// parameters from the link the offers grid renders (it already has
    /// them in memory from the list it's displaying).
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> EditOffer(long quoteOfferId, long quoteRequestId, long underwriterId, decimal premiumAmount)
    {
        var underwritersResult = await _apiClient.GetAsync<List<UnderwriterOption>>("/api/underwriters?activeOnly=true");

        var vm = new EditQuoteOfferViewModel
        {
            QuoteOfferId = quoteOfferId,
            QuoteRequestId = quoteRequestId,
            UnderwriterId = underwriterId,
            PremiumAmount = premiumAmount
        };

        ViewBag.UnderwriterOptions = underwritersResult.Success ? underwritersResult.Data ?? new() : new List<UnderwriterOption>();
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditOffer(EditQuoteOfferViewModel model)
    {
        if (!ModelState.IsValid || model.UnderwriterId is null)
        {
            var underwritersResult = await _apiClient.GetAsync<List<UnderwriterOption>>("/api/underwriters?activeOnly=true");
            ViewBag.UnderwriterOptions = underwritersResult.Success ? underwritersResult.Data ?? new() : new List<UnderwriterOption>();
            model.ErrorMessage = "Pick an underwriter and enter a valid premium amount.";
            return View(model);
        }

        var fields = new Dictionary<string, string>
        {
            ["UnderwriterId"] = model.UnderwriterId.Value.ToString(),
            ["PremiumAmount"] = model.PremiumAmount.ToString(System.Globalization.CultureInfo.InvariantCulture)
        };

        var result = await _apiClient.PutFormAsync<object>($"/api/quote-offers/{model.QuoteOfferId}", model.Document, "Document", fields);

        TempData["StatusMessage"] = result.Success ? "Offer updated." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteOffer(long quoteOfferId, long quoteRequestId)
    {
        var result = await _apiClient.DeleteAsync<object>($"/api/quote-offers/{quoteOfferId}");

        TempData["StatusMessage"] = result.Success ? "Offer deleted." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = quoteRequestId });
    }

    /// <summary>
    /// Add-ons editor GET. Same "no single-offer endpoint" reasoning as
    /// EditOffer: the offer's own fields travel here as query parameters
    /// from the offer row's link, and the currently-saved add-ons are
    /// fetched from GET /api/quoterequests/{quoteRequestId}/offers/{quoteOfferId}/riders.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> EditRiders(long quoteOfferId, long quoteRequestId, string underwriterName, decimal premiumAmount)
    {
        var vm = new OfferRidersEditViewModel
        {
            QuoteOfferId = quoteOfferId,
            QuoteRequestId = quoteRequestId,
            UnderwriterName = underwriterName,
            PremiumAmount = premiumAmount
        };

        var ridersResult = await _apiClient.GetAsync<List<QuoteOfferRiderItem>>($"/api/quoterequests/{quoteRequestId}/offers/{quoteOfferId}/riders");
        if (ridersResult.Success && ridersResult.Data is not null)
        {
            vm.Riders = ridersResult.Data;
        }

        return View(vm);
    }

    /// <summary>
    /// Saves the whole add-on set - one PUT to /api/quote-offers/{id}/riders
    /// that replaces the offer's existing lines (the old set is soft-deleted
    /// server-side). Blank Name rows are dropped before sending.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditRiders(OfferRidersEditViewModel model)
    {
        if (model.QuoteOfferId <= 0 || model.QuoteRequestId <= 0)
        {
            TempData["StatusMessage"] = "Missing offer details.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
        }

        var validRows = (model.Riders ?? new()).Where(r => !string.IsNullOrWhiteSpace(r.Name)).ToList();

        var payload = new { Riders = validRows.Select(r => new { r.Name, r.Amount, r.Note }) };

        var result = await _apiClient.PutAsync<object>($"/api/quote-offers/{model.QuoteOfferId}/riders", payload);

        TempData["StatusMessage"] = result.Success ? "Add-ons updated." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Details), new { id = model.QuoteRequestId });
    }

    /// <summary>
    /// URL the browser uses to download an offer document. Offer documents
    /// now live in a shared storage folder on the API host (outside its
    /// webroot, no public static-file URL), so downloads go through this
    /// portal's own proxy action - it forwards the signed-in user's token to
    /// the API and streams the file back.
    /// </summary>
    private string? BuildDocumentUrl(long quoteOfferId)
    {
        return Url.Action(nameof(DownloadOffer), new { id = quoteOfferId });
    }

    /// <summary>
    /// Proxies an authenticated offer-document download from the API - offer
    /// documents are stored in a shared folder (QuoteOffersStorage:Root)
    /// outside the API's webroot, so they can only be fetched through the
    /// API's [Authorize] endpoint, which needs a Bearer token the browser
    /// doesn't have. This action attaches the signed-in user's token and
    /// streams the bytes through unchanged.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> DownloadOffer(long id)
    {
        var streamResult = await _apiClient.GetStreamAsync($"/api/quote-offers/{id}/document");

        if (streamResult is null)
        {
            TempData["StatusMessage"] = "Document not found.";
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        return File(streamResult.Content, streamResult.ContentType ?? "application/octet-stream");
    }

    private async Task<List<StaffOption>> GetAssignableStaffAsync()
    {
        var result = await _apiClient.GetAsync<List<StaffOption>>("/api/staff?roleCode=SP&status=ACTIVE&pageSize=200");
        return result.Success ? result.Data ?? new List<StaffOption>() : new List<StaffOption>();
    }

    private static void ResolveAssignedNames(IEnumerable<QuoteRequestItem> items, List<StaffOption> staff)
    {
        foreach (var item in items)
        {
            if (item.AssignedBackofficeUserId is null)
            {
                continue;
            }

            var match = staff.FirstOrDefault(s => s.UserId == item.AssignedBackofficeUserId.Value);
            item.AssignedToName = match?.FullName ?? $"User #{item.AssignedBackofficeUserId.Value}";
        }
    }
}
