using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Infrastructure.Integrations.Scapi;

/// <summary>
/// D-MVIC vehicle search over the existing SCAPI gateway. Mirrors the call
/// Bima makes from InsuranceManagementController.GetVehicleDetails:
/// interface DMVICINTERMEDIARY, request_type vehicle_search, body
/// { VehicleRegistrationNumber: "..." }, response output.callbackObj.Vehicle.
/// No new vendor credentials are needed - the same gateway credentials that
/// issue our NTSA certificates are used here.
/// </summary>
public sealed class DmvicVehicleLookupClient : IVehicleLookupClient
{
    private const string InterfaceName = "DMVICINTERMEDIARY";
    private const string RequestType = "vehicle_search";

    private readonly IScapiGatewayClient _gateway;
    private readonly ILoggerManager _logger;

    public DmvicVehicleLookupClient(IScapiGatewayClient gateway, ILoggerManager logger)
    {
        _gateway = gateway;
        _logger = logger;
    }

    public async Task<VehicleLookupResult?> LookupAsync(string registrationNumber, CancellationToken ct = default)
    {
        var plate = Regex.Replace((registrationNumber ?? string.Empty).ToUpperInvariant(), @"[^A-Z0-9]", string.Empty);
        if (plate.Length < 3)
        {
            return null;
        }

        var externalRef = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");

        JsonObject? response;
        try
        {
            response = await _gateway.InvokeAsync(
                new ScapiMessageRoute
                {
                    Interface = InterfaceName,
                    RequestType = RequestType,
                    ExternalRefNumber = externalRef
                },
                new JsonObject { ["VehicleRegistrationNumber"] = plate });
        }
        catch (Exception ex)
        {
            _logger.LogError($"D-MVIC vehicle lookup ref={externalRef} plate={plate}: gateway call failed.", ex);
            return null;
        }

        if (response is null)
        {
            _logger.LogWarn($"D-MVIC vehicle lookup ref={externalRef} plate={plate}: gateway returned no response.");
            return null;
        }

        // Direct and SCAPI-wrapped responses both occur in this gateway.
        var output = response["output"] as JsonObject
                     ?? (response["error_desc"] as JsonObject)?["output"] as JsonObject;
        if (output is null)
        {
            _logger.LogWarn($"D-MVIC vehicle lookup ref={externalRef} plate={plate}: unexpected response {response.ToJsonString()}.");
            return null;
        }

        var success = output["success"]?.ToString();
        if (success is not ("true" or "True"))
        {
            _logger.LogWarn($"D-MVIC vehicle lookup ref={externalRef} plate={plate} was not successful: {output.ToJsonString()}.");
            return null;
        }

        var vehicle = (output["callbackObj"] as JsonObject)?["Vehicle"] as JsonObject;
        if (vehicle is null)
        {
            _logger.LogWarn($"D-MVIC vehicle lookup ref={externalRef} plate={plate}: no Vehicle in response.");
            return null;
        }

        int? year = int.TryParse(Text(vehicle, "VehicleRegistrationYear"), out var parsedYear) ? parsedYear : null;

        _logger.LogInfo($"D-MVIC vehicle lookup ref={externalRef} plate={plate}: found {Text(vehicle, "VehicleMake")} {Text(vehicle, "VehicleModel")}.");

        return new VehicleLookupResult
        {
            RegistrationNumber = Text(vehicle, "VehicleRegistrationNumber"),
            ChassisNumber = Text(vehicle, "ChassisNumber"),
            EngineNumber = Text(vehicle, "EngineNumber"),
            Make = Text(vehicle, "VehicleMake"),
            Model = Text(vehicle, "VehicleModel"),
            YearOfManufacture = year,
            BodyType = Text(vehicle, "BodyType"),
            Color = Text(vehicle, "color"),
            PassengerCapacity = NullableText(vehicle, "passengerCapacity"),
            CubicCapacity = NullableText(vehicle, "cubicCapacity")
        };
    }

    private static string Text(JsonObject obj, string key) => NullableText(obj, key) ?? string.Empty;

    private static string? NullableText(JsonObject obj, string key)
    {
        var value = obj[key]?.ToString()?.Trim();
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }
}
