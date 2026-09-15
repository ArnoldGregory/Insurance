using System.Data;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class VehicleRepository : IVehicleRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public VehicleRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public async Task<StoredProcResult<long?>> CreateAsync(
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
        long actorId)
    {
        var vehicleIdParam = new MySqlParameter("o_vehicle_id", MySqlDbType.Int64) { Direction = ParameterDirection.Output };

        var parameters = new List<MySqlParameter>
        {
            new("p_client_id", clientId),
            new("p_make", (object?)make ?? DBNull.Value),
            new("p_model", (object?)model ?? DBNull.Value),
            new("p_reg_no", (object?)regNo ?? DBNull.Value),
            new("p_chassis_no", (object?)chassisNo ?? DBNull.Value),
            new("p_engine_no", (object?)engineNo ?? DBNull.Value),
            new("p_yearofmanufacture", (object?)yearOfManufacture ?? DBNull.Value),
            new("p_vehicle_type", (object?)vehicleType ?? DBNull.Value),
            // p_body_type - the proc parameter is deliberately named
            // differently from the Vehicles.p_bodytype column it maps to
            // (see the proc's own comment: avoids a parameter/column name
            // collision inside the proc body).
            new("p_body_type", (object?)bodyType ?? DBNull.Value),
            new("p_fueltype", (object?)fuelType ?? DBNull.Value),
            new("p_cubiccapacity", (object?)cubicCapacity ?? DBNull.Value),
            new("p_color", (object?)color ?? DBNull.Value),
            new("p_logbook", (object?)logbook ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId),
            vehicleIdParam
        };

        var result = await _executor.ExecuteAsync("usp_Vehicle_Create", parameters);

        return new StoredProcResult<long?>
        {
            ResultCode = result.ResultCode,
            ResultMessage = result.ResultMessage,
            Data = vehicleIdParam.Value is null or DBNull ? null : Convert.ToInt64(vehicleIdParam.Value)
        };
    }

    public Task<StoredProcResult<Vehicle?>> GetByIdAsync(long vehicleId)
    {
        var parameters = new List<MySqlParameter> { new("p_vehicle_id", vehicleId) };
        return _executor.ExecuteQuerySingleAsync("usp_Vehicle_GetById", parameters, MapRow);
    }

    public Task<StoredProcResult<Vehicle?>> GetByRegNoAsync(string regNo)
    {
        var parameters = new List<MySqlParameter> { new("p_reg_no", regNo) };
        return _executor.ExecuteQuerySingleAsync("usp_Vehicle_GetByRegNo", parameters, MapRow);
    }

    public async Task<StoredProcResult<List<VehicleSummary>>> GetListByClientAsync(long clientId)
    {
        var parameters = new List<MySqlParameter> { new("p_client_id", clientId) };
        return await _executor.ExecuteQueryAsync("usp_Vehicle_GetListByClient", parameters, MapSummaryRow);
    }

    public Task<StoredProcResult> UpdateAsync(
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
        long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_vehicle_id", vehicleId),
            new("p_make", (object?)make ?? DBNull.Value),
            new("p_model", (object?)model ?? DBNull.Value),
            new("p_reg_no", (object?)regNo ?? DBNull.Value),
            new("p_chassis_no", (object?)chassisNo ?? DBNull.Value),
            new("p_engine_no", (object?)engineNo ?? DBNull.Value),
            new("p_yearofmanufacture", (object?)yearOfManufacture ?? DBNull.Value),
            new("p_vehicle_type", (object?)vehicleType ?? DBNull.Value),
            new("p_body_type", (object?)bodyType ?? DBNull.Value),
            new("p_fueltype", (object?)fuelType ?? DBNull.Value),
            new("p_cubiccapacity", (object?)cubicCapacity ?? DBNull.Value),
            new("p_color", (object?)color ?? DBNull.Value),
            new("p_logbook", (object?)logbook ?? DBNull.Value),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Vehicle_Update", parameters);
    }

    public Task<StoredProcResult> DeleteAsync(long vehicleId, string actorType, long actorId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_vehicle_id", vehicleId),
            new("p_actor_type", actorType),
            new("p_actor_id", actorId)
        };

        return _executor.ExecuteAsync("usp_Vehicle_Delete", parameters);
    }

    private static Vehicle MapRow(MySqlDataReader reader)
    {
        return new Vehicle
        {
            VehicleId = reader.GetInt64("vehicle_id"),
            ClientId = reader.GetInt64("client_id"),
            Make = reader.IsDBNull(reader.GetOrdinal("make")) ? null : reader.GetString("make"),
            Model = reader.IsDBNull(reader.GetOrdinal("model")) ? null : reader.GetString("model"),
            RegNo = reader.IsDBNull(reader.GetOrdinal("reg_no")) ? null : reader.GetString("reg_no"),
            ChassisNo = reader.IsDBNull(reader.GetOrdinal("chassis_no")) ? null : reader.GetString("chassis_no"),
            EngineNo = reader.IsDBNull(reader.GetOrdinal("engine_no")) ? null : reader.GetString("engine_no"),
            YearOfManufacture = reader.IsDBNull(reader.GetOrdinal("yearofmanufacture")) ? null : reader.GetInt32("yearofmanufacture"),
            VehicleType = reader.IsDBNull(reader.GetOrdinal("vehicle_type")) ? null : reader.GetString("vehicle_type"),
            // "p_bodytype" - the real column name, no alias in the SELECT list.
            BodyType = reader.IsDBNull(reader.GetOrdinal("p_bodytype")) ? null : reader.GetString("p_bodytype"),
            FuelType = reader.IsDBNull(reader.GetOrdinal("fueltype")) ? null : reader.GetString("fueltype"),
            CubicCapacity = reader.IsDBNull(reader.GetOrdinal("cubiccapacity")) ? null : reader.GetString("cubiccapacity"),
            Color = reader.IsDBNull(reader.GetOrdinal("color")) ? null : reader.GetString("color"),
            Logbook = reader.IsDBNull(reader.GetOrdinal("logbook")) ? null : reader.GetString("logbook"),
            CreatedBy = reader.IsDBNull(reader.GetOrdinal("created_by")) ? null : reader.GetInt64("created_by"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }

    private static VehicleSummary MapSummaryRow(MySqlDataReader reader)
    {
        return new VehicleSummary
        {
            VehicleId = reader.GetInt64("vehicle_id"),
            ClientId = reader.GetInt64("client_id"),
            Make = reader.IsDBNull(reader.GetOrdinal("make")) ? null : reader.GetString("make"),
            Model = reader.IsDBNull(reader.GetOrdinal("model")) ? null : reader.GetString("model"),
            RegNo = reader.IsDBNull(reader.GetOrdinal("reg_no")) ? null : reader.GetString("reg_no"),
            ChassisNo = reader.IsDBNull(reader.GetOrdinal("chassis_no")) ? null : reader.GetString("chassis_no"),
            EngineNo = reader.IsDBNull(reader.GetOrdinal("engine_no")) ? null : reader.GetString("engine_no"),
            YearOfManufacture = reader.IsDBNull(reader.GetOrdinal("yearofmanufacture")) ? null : reader.GetInt32("yearofmanufacture"),
            VehicleType = reader.IsDBNull(reader.GetOrdinal("vehicle_type")) ? null : reader.GetString("vehicle_type"),
            BodyType = reader.IsDBNull(reader.GetOrdinal("p_bodytype")) ? null : reader.GetString("p_bodytype"),
            FuelType = reader.IsDBNull(reader.GetOrdinal("fueltype")) ? null : reader.GetString("fueltype"),
            CubicCapacity = reader.IsDBNull(reader.GetOrdinal("cubiccapacity")) ? null : reader.GetString("cubiccapacity"),
            Color = reader.IsDBNull(reader.GetOrdinal("color")) ? null : reader.GetString("color"),
            Logbook = reader.IsDBNull(reader.GetOrdinal("logbook")) ? null : reader.GetString("logbook"),
            CreatedOn = reader.GetDateTime("created_on")
        };
    }
}
