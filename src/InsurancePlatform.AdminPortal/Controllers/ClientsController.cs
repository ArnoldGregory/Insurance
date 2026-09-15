using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// Client CRUD, mirroring InsurancePlatform.Api's ClientsController one for
/// one. Class-level [Authorize(Roles = AllStaff)] matches GetList's own
/// [Authorize(Roles=SA,AA,AG,SP)] on the API side - everyone who can sign
/// into this portal can at least browse clients. Create/Edit/Delete then
/// layer a SECOND, narrower [Authorize(Roles=...)] on top - ASP.NET Core
/// requires every stacked [Authorize] attribute to pass (logical AND
/// across attributes, logical OR within one Roles string), so e.g. Create
/// effectively ends up SA-excluded even though the class-level attribute
/// alone would have let SA in. These are UX-level gates only ("don't even
/// show the button/form") - CreateClientRequest/EditClient's real
/// enforcement is the API's own [Authorize(Policy=...)], which this cannot
/// bypass no matter what a hand-edited request does.
/// </summary>
[Authorize(Roles = RoleCodes.AllStaff)]
public class ClientsController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public ClientsController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? search, int pageNumber = 1, int pageSize = 20)
    {
        pageNumber = pageNumber < 1 ? 1 : pageNumber;
        pageSize = pageSize is < 1 or > 200 ? 20 : pageSize;

        var query = $"/api/clients?pageNumber={pageNumber}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(search))
        {
            query += $"&search={Uri.EscapeDataString(search)}";
        }

        var result = await _apiClient.GetAsync<ClientListPage>(query);
        var page = result.Success ? result.Data ?? new ClientListPage() : new ClientListPage();

        var roleCode = User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;

        var vm = new ClientIndexViewModel
        {
            Items = page.Items,
            TotalCount = page.TotalCount,
            Search = search,
            PageNumber = pageNumber,
            PageSize = pageSize,
            CanCreate = RoleCodes.ClientCreators.Split(',').Contains(roleCode),
            CanEdit = RoleCodes.ClientEditors.Split(',').Contains(roleCode),
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
        var result = await _apiClient.GetAsync<ClientDetail>($"/api/clients/{id}");

        if (!result.Success || result.Data is null)
        {
            TempData["StatusMessage"] = result.Message;
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var roleCode = User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;
        ViewData["CanEdit"] = RoleCodes.ClientEditors.Split(',').Contains(roleCode);

        return View(result.Data);
    }

    // ---- Create (2 steps: resolve ID number, then fill in the rest) ----

    [Authorize(Roles = RoleCodes.ClientCreators)]
    [HttpGet]
    public IActionResult Create()
    {
        return View(new ClientLookupViewModel());
    }

    [Authorize(Roles = RoleCodes.ClientCreators)]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(ClientLookupViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var result = await _apiClient.GetAsync<ClientLookupResult>($"/api/clients/resolve/{Uri.EscapeDataString(model.IdNo)}");

        if (!result.Success || result.Data is null)
        {
            model.ErrorMessage = result.Message;
            return View(model);
        }

        var lookup = result.Data;

        if (lookup.MatchStatus != "NOT_FOUND")
        {
            // Already on file - send them to the existing record instead of
            // letting usp_Client_Create reject a duplicate id_no.
            TempData["StatusMessage"] = $"A client with ID number \"{model.IdNo}\" already exists.";
            return RedirectToAction(nameof(Details), new { id = lookup.ClientId });
        }

        var details = new ClientCreateViewModel
        {
            IdNo = model.IdNo,
            FullName = lookup.FullName ?? string.Empty,
            Email = lookup.Email,
            Phone = lookup.Phone ?? string.Empty,
            KraPin = lookup.KraPin,
            WasEnrichedFromGovConnect = lookup.EnrichedFromGovConnect
        };

        return View("CreateDetails", details);
    }

    [Authorize(Roles = RoleCodes.ClientCreators)]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(ClientCreateViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View("CreateDetails", model);
        }

        var result = await _apiClient.PostAsync<CreateClientResultData>("/api/clients", new
        {
            IdNo = model.IdNo,
            FullName = model.FullName,
            Dob = model.Dob,
            Email = model.Email,
            Phone = model.Phone,
            Address = model.Address,
            KraPin = model.KraPin,
            RegistrationChannel = model.RegistrationChannel
        });

        if (!result.Success)
        {
            model.ErrorMessage = result.Message;
            return View("CreateDetails", model);
        }

        TempData["StatusMessage"] = $"\"{model.FullName}\" was registered.";
        return RedirectToAction(nameof(Details), new { id = result.Data?.ClientId });
    }

    // ---- Edit ----

    [Authorize(Roles = RoleCodes.ClientEditors)]
    [HttpGet]
    public async Task<IActionResult> Edit(long id)
    {
        var result = await _apiClient.GetAsync<ClientDetail>($"/api/clients/{id}");

        if (!result.Success || result.Data is null)
        {
            TempData["StatusMessage"] = result.Message;
            TempData["StatusIsError"] = true;
            return RedirectToAction(nameof(Index));
        }

        var client = result.Data;
        var model = new ClientEditViewModel
        {
            ClientId = client.ClientId,
            IdNo = client.IdNo,
            FullName = client.FullName,
            Dob = client.Dob,
            Email = client.Email,
            Phone = client.Phone,
            Address = client.Address,
            KraPin = client.KraPin
        };

        return View(model);
    }

    [Authorize(Roles = RoleCodes.ClientEditors)]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(ClientEditViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var result = await _apiClient.PutAsync<object>($"/api/clients/{model.ClientId}", new
        {
            FullName = model.FullName,
            Dob = model.Dob,
            Email = model.Email,
            Phone = model.Phone,
            Address = model.Address,
            KraPin = model.KraPin
        });

        if (!result.Success)
        {
            model.ErrorMessage = result.Message;
            return View(model);
        }

        TempData["StatusMessage"] = $"\"{model.FullName}\" was updated.";
        return RedirectToAction(nameof(Details), new { id = model.ClientId });
    }

    [Authorize(Roles = RoleCodes.ClientEditors)]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(long id)
    {
        var result = await _apiClient.DeleteAsync<object>($"/api/clients/{id}");

        TempData["StatusMessage"] = result.Success ? "Client record deleted." : result.Message;
        TempData["StatusIsError"] = !result.Success;

        return RedirectToAction(nameof(Index));
    }

    /// <summary>POST /api/clients's success payload shape - just the new id.</summary>
    private class CreateClientResultData
    {
        public long ClientId { get; set; }
    }
}
