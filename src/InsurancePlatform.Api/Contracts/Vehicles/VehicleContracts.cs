namespace InsurancePlatform.Api.Contracts.Vehicles;

/// <summary>Adds a vehicle - every field here is optional.</summary>
// ClientId is NOT here - it comes from the route
// (POST /api/clients/{clientId}/vehicles), not the body. Every other field
// is genuinely optional: the Vehicles table allows a record with almost no
// details filled in, and usp_Vehicle_Create imposes no extra required-field
// check beyond client_id existing.
public class CreateVehicleRequest
{
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
}

/// <summary>Partial update - a null field keeps its current value.</summary>
// Same COALESCE semantics as UpdateClientRequest - fields left out are not
// cleared, just left alone.
public class UpdateVehicleRequest
{
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
}
