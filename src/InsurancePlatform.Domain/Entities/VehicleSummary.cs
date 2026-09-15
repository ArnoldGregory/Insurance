namespace InsurancePlatform.Domain.Entities;

/// <summary>
/// One row from usp_Vehicle_GetListByClient - same fields as Vehicle except
/// CreatedBy, which that query doesn't select at all.
/// </summary>
public class VehicleSummary
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
    public DateTime CreatedOn { get; set; }
}
