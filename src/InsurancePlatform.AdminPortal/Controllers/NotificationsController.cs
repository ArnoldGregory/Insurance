using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Backs the topbar notification bell (see _Layout.cshtml + site.js's
/// polling code). This is a "polling badge", not real-time push (SignalR/
/// WebSockets) - the browser just calls GET /Notifications/Summary every
/// ~45 seconds and repaints the badge/dropdown from whatever it gets back.
/// That was a deliberate, explicit choice over real-time infra: it needs no
/// new server-side plumbing at all, since both numbers it reports are
/// already available from endpoints QuoteRequestsController's own screens
/// already call:
///   - "pending in queue"   -> GET /api/quoterequests/summary, summed
///   - "assigned to me"     -> GET /api/quoterequests?status=IN_PROGRESS&amp;assignedBackofficeUserId={me}
/// This controller only exists because the browser can't call
/// InsurancePlatform.Api directly - the JWT lives server-side in this
/// portal's own auth cookie (see InsuranceApiClient), never sent to client
/// JS. So the bell polls THIS portal, which forwards to the real API using
/// the same signed-in caller's token exactly like every other screen does.
/// </summary>
[Authorize(Roles = RoleCodes.QuoteBackoffice)]
[Route("notifications")]
public class NotificationsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public NotificationsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> Summary()
    {
        var userIdRaw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var hasUserId = long.TryParse(userIdRaw, out var currentUserId);

        var summaryTask = _apiClient.GetAsync<List<QuoteRequestProductSummary>>("/api/quoterequests/summary");
        var mineTask = hasUserId
            ? _apiClient.GetAsync<QuoteRequestListPage>($"/api/quoterequests?status=IN_PROGRESS&assignedBackofficeUserId={currentUserId}&pageNumber=1&pageSize=1")
            : Task.FromResult(new ApiResponse<QuoteRequestListPage> { Success = true, Data = new QuoteRequestListPage() });

        await Task.WhenAll(summaryTask, mineTask);

        var summaryResult = summaryTask.Result;
        var mineResult = mineTask.Result;

        // Sum of every manual-quote product's own PendingCount - the same
        // number the Index screen's summary cards already show per product,
        // just totalled here into one queue-wide figure for the badge.
        var pendingCount = summaryResult.Success
            ? (summaryResult.Data ?? new List<QuoteRequestProductSummary>()).Sum(s => s.PendingCount)
            : 0;

        // pageSize=1 above - this only needs the TotalCount the API returns
        // alongside that one row, not the row itself, to avoid pulling back
        // a whole page of data just to count it.
        var assignedToMeCount = mineResult.Success ? mineResult.Data?.TotalCount ?? 0 : 0;

        return Json(new
        {
            pendingCount,
            assignedToMeCount,
            totalCount = pendingCount + assignedToMeCount
        });
    }
}
