namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One full Vehicles row, as returned by usp_Vehicle_GetById and
/// usp_Vehicle_GetByRegNo. Every field except VehicleId/ClientId/CreatedOn
/// is genuinely nullable in the Vehicles table itself - a vehicle can be
/// created with almost no details filled in, so that's reflected here
/// rather than papered over.
///
/// One naming quirk worth knowing: the database column is literally called
/// p_bodytype (not body_type) - carried over from whatever system this
/// schema originated from. BodyType here is just the clean C# name;
/// VehicleRepository's MapRow is what actually reads the odd column name.
/// </summary>
public class Vehicle
{
    public long VehicleId { get; set; }
    public long ClientId { get; set; }
    public string? Make { get; set; }
    public string? Model { get; set; }
    public string? RegNo { get; set; }
    public string? ChassisNo { get; set; }
    public string? EngineNo { get; set; }
    public int? YearOfManufacture { get; set; }
    public string? VehicleType { get; set; }
    public string? BodyType { get; set; }
    public string? FuelType { get; set; }
    public string? CubicCapacity { get; set; }
    public string? Color { get; set; }
    public string? Logbook { get; set; }

    /// <summary>
    /// user_id of the staff member who created this vehicle record, or null
    /// if it was created by/for the client directly (see usp_Vehicle_Create:
    /// only set when p_actor_type = 'USER'). Not selected at all by
    /// usp_Vehicle_GetListByClient - see VehicleSummary.
    /// </summary>
    public long? CreatedBy { get; set; }

    public DateTime CreatedOn { get; set; }
}
