using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;


public class ProductRepository : IProductRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public ProductRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public Task<StoredProcResult<List<Product>>> GetListAsync()
    {
        return _executor.ExecuteQueryAsync( "usp_Product_GetList", Array.Empty<MySqlParameter>(), MapRow);
    }

    public Task<StoredProcResult<List<MotorCategory>>> GetMotorCategoriesAsync()
    {
        return _executor.ExecuteQueryAsync("usp_MotorCategory_GetList", Array.Empty<MySqlParameter>(), MapMotorCategoryRow);
    }

    public Task<StoredProcResult<List<MotorVehicleClass>>> GetMotorVehicleClassesAsync()
    {
        return _executor.ExecuteQueryAsync("usp_MotorVehicleClass_GetList", Array.Empty<MySqlParameter>(), MapMotorVehicleClassRow);
    }

    public Task<StoredProcResult<List<Period>>> GetPeriodsAsync()
    {
        return _executor.ExecuteQueryAsync("usp_Period_GetList", Array.Empty<MySqlParameter>(), MapPeriodRow);
    }

    public Task<StoredProcResult<List<PolicyLevel>>> GetPolicyLevelsAsync()
    {
        return _executor.ExecuteQueryAsync("usp_PolicyLevel_GetList", Array.Empty<MySqlParameter>(), MapPolicyLevelRow);
    }

    private static Product MapRow(MySqlDataReader reader)
    {
        return new Product
        {
            ProductId = reader.GetInt64("product_id"),
            Name = reader.GetString("name"),
            Code = reader.GetString("code"),
            PricingMethod = reader.GetString("pricing_method"),
            IsActive = reader.GetBoolean("is_active")
        };
    }

    private static MotorCategory MapMotorCategoryRow(MySqlDataReader reader)
    {
        return new MotorCategory
        {
            MotorCategoryId = reader.GetInt64("motor_category_id"),
            ProductId = reader.GetInt64("product_id"),
            Name = reader.GetString("name")
        };
    }

    private static MotorVehicleClass MapMotorVehicleClassRow(MySqlDataReader reader)
    {
        return new MotorVehicleClass
        {
            VehicleClassId = reader.GetInt64("vehicle_class_id"),
            Name = reader.GetString("name"),
            RequiresTonnage = reader.GetBoolean("requires_tonnage"),
            PolicyLevelId = reader.IsDBNull(reader.GetOrdinal("policy_level_id")) ? null : reader.GetInt32("policy_level_id")
        };
    }

    private static Period MapPeriodRow(MySqlDataReader reader)
    {
        return new Period
        {
            PeriodId = reader.GetInt64("period_id"),
            Name = reader.GetString("name"),
            DmvicCode = reader.IsDBNull(reader.GetOrdinal("dmvic_code")) ? null : reader.GetString("dmvic_code")
        };
    }

    private static PolicyLevel MapPolicyLevelRow(MySqlDataReader reader)
    {
        return new PolicyLevel
        {
            PolicyLevelId = reader.GetInt32("policy_level_id"),
            Name = reader.GetString("name")
        };
    }
}
