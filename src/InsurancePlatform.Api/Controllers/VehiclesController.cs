using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Contracts.Vehicles;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>Vehicle CRUD - always scoped under a client.</summary>
// Create and "list mine" are routed as /api/clients/{clientId}/vehicles
// (absolute route override, ignoring this controller's own api/vehicles
// prefix); GetById/Update/Delete use the vehicle's own id under
// api/vehicles directly. Same permission model as ClientsController -
// Create/Update/Delete need CreateClient/EditClient (no separate
// CreateVehicle/EditVehicle; vehicles aren't managed independently of
// their client), GetById/GetListByClient are [Authorize]-only with a
// Client-role caller restricted to their own client's vehicles.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VehiclesController : BaseApiController
{
    private readonly IVehicleRepository _vehicleRepository;
    private readonly IClientRepository _clientRepository;
    private readonly ILoggerManager _logger;

    public VehiclesController(
        IVehicleRepository vehicleRepository,
        IClientRepository clientRepository,
        ILoggerManager logger,
        CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _vehicleRepository = vehicleRepository;
        _clientRepository = clientRepository;
        _logger = logger;
    }

    /// <summary>Adds a vehicle under a client.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.CreateClient)]
    [HttpPost("/api/clients/{clientId}/vehicles")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create(long clientId, [FromBody] CreateVehicleRequest request)
    {
        var result = await _vehicleRepository.CreateAsync(
            clientId, request.Make, request.Model, request.RegNo, request.ChassisNo, request.EngineNo,
            request.YearOfManufacture, request.VehicleType, request.BodyType, request.FuelType,
            request.CubicCapacity, request.Color, request.Logbook, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            _logger.LogWarn($"Vehicle create failed for client_id={clientId}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Vehicle created: vehicle_id={result.Data}, client_id={clientId}, by user_id={CurrentUserId}.");
        return Success(new { VehicleId = result.Data }, result.ResultMessage);
    }

    /// <summary>Fetches one vehicle by its own id.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(ApiResponse<Vehicle>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(long id)
    {
        var result = await _vehicleRepository.GetByIdAsync(id);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        if (!await CallerOwnsClientAsync(result.Data.ClientId))
        {
            return BusinessFailure("Vehicle not found.");
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Dedup lookup - check before Create so a renewal reuses the existing vehicle_id.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("by-reg-no/{regNo}")]
    [ProducesResponseType(typeof(ApiResponse<Vehicle>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetByRegNo(string regNo)
    {
        var result = await _vehicleRepository.GetByRegNoAsync(regNo);

        if (!result.IsSuccess || result.Data is null)
        {
            return BusinessFailure(result.ResultMessage);
        }

        if (!await CallerOwnsClientAsync(result.Data.ClientId))
        {
            return BusinessFailure("Vehicle not found.");
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Lists all vehicles under one client.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet("/api/clients/{clientId}/vehicles")]
    [ProducesResponseType(typeof(ApiResponse<List<VehicleSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetListByClient(long clientId)
    {
        if (!await CallerOwnsClientAsync(clientId))
        {
            return BusinessFailure("Client not found.");
        }

        var result = await _vehicleRepository.GetListByClientAsync(clientId);

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_Vehicle_GetListByClient returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Full update of a vehicle's details.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.EditClient)]
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateVehicleRequest request)
    {
        var result = await _vehicleRepository.UpdateAsync(
            id, request.Make, request.Model, request.RegNo, request.ChassisNo, request.EngineNo,
            request.YearOfManufacture, request.VehicleType, request.BodyType, request.FuelType,
            request.CubicCapacity, request.Color, request.Logbook, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Vehicle updated: vehicle_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Soft-deletes a vehicle.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [Authorize(Policy = PermissionCodes.EditClient)]
    [HttpDelete("{id}")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Delete(long id)
    {
        var result = await _vehicleRepository.DeleteAsync(id, "USER", CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Vehicle deleted (soft): vehicle_id={id}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>True if the caller is allowed to see this client's vehicles.</summary>
    // Staff (anyone but role CL) always "owns" every client for this purpose
    // - only a Client-role caller gets restricted, and only to the one
    // client record linked to their own user_id. Costs one extra
    // usp_Client_GetById call for Client-role callers; staff callers skip it
    // entirely.
    private async Task<bool> CallerOwnsClientAsync(long clientId)
    {
        if (CurrentRoleCode != RoleCodes.Client)
        {
            return true;
        }

        var clientResult = await _clientRepository.GetByIdAsync(clientId);
        return clientResult.IsSuccess && clientResult.Data?.UserId == CurrentUserId;
    }
}
