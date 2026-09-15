using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;

public interface IVehicleRepository
{
    /// <summary>
    /// Wraps usp_Vehicle_Create. Every field except clientId is nullable -
    /// the Vehicles table itself allows a record with almost no details, and
    /// the proc doesn't impose any extra required-field check beyond that.
    /// The proc dedupes on reg_no/chassis_no itself (returns a Duplicate
    /// result if either is already in use), so there's no need to call
    /// GetByRegNoAsync first unless you want to show the existing vehicle to
    /// the caller before they resubmit.
    /// </summary>
    Task<StoredProcResult<long?>> CreateAsync(
        long clientId,
        string? make,
        string? model,
        string? regNo,
        string? chassisNo,
        string? engineNo,
        int? yearOfManufacture,
        string? vehicleType,
        string? bodyType,
        string? fuelType,
        string? cubicCapacity,
        string? color,
        string? logbook,
        string actorType,
        long actorId);

    /// <summary>Wraps usp_Vehicle_GetById.</summary>
    Task<StoredProcResult<Vehicle?>> GetByIdAsync(long vehicleId);

    /// <summary>
    /// Wraps usp_Vehicle_GetByRegNo - the dedup lookup the proc's own doc
    /// comment describes: call before Create so a renewal/re-registration
    /// reuses the existing vehicle_id instead of hitting Create's own
    /// duplicate rejection.
    /// </summary>
    Task<StoredProcResult<Vehicle?>> GetByRegNoAsync(string regNo);

    /// <summary>Wraps usp_Vehicle_GetListByClient.</summary>
    Task<StoredProcResult<List<VehicleSummary>>> GetListByClientAsync(long clientId);

    /// <summary>
    /// Wraps usp_Vehicle_Update. Same partial-update-via-COALESCE semantics
    /// as IClientRepository.UpdateAsync - a null field means "leave alone."
    /// </summary>
    Task<StoredProcResult> UpdateAsync(
        long vehicleId,
        string? make,
        string? model,
        string? regNo,
        string? chassisNo,
        string? engineNo,
        int? yearOfManufacture,
        string? vehicleType,
        string? bodyType,
        string? fuelType,
        string? cubicCapacity,
        string? color,
        string? logbook,
        string actorType,
        long actorId);

    /// <summary>Wraps usp_Vehicle_Delete - soft delete (isdeleted = 1).</summary>
    Task<StoredProcResult> DeleteAsync(long vehicleId, string actorType, long actorId);
}
