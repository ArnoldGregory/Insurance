namespace InsurancePlatform.Application.Integrations;

/// <summary>
/// Looks a registration number up against the motor registry (D-MVIC/NTSA via
/// SCAPI) so the caller can prefill the vehicle form instead of asking the
/// customer to type chassis/engine details from their logbook.
/// </summary>
public interface IVehicleLookupClient
{
    /// <summary>Returns null when the plate is unknown or the registry is unavailable.</summary>
    Task<VehicleLookupResult?> LookupAsync(string registrationNumber, CancellationToken ct = default);
}

public sealed class VehicleLookupResult
{
    public string RegistrationNumber { get; set; } = string.Empty;
    public string ChassisNumber { get; set; } = string.Empty;
    public string EngineNumber { get; set; } = string.Empty;
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public int? YearOfManufacture { get; set; }
    public string BodyType { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string? PassengerCapacity { get; set; }
    public string? CubicCapacity { get; set; }
}
