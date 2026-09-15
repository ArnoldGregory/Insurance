using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;

namespace InsurancePlatform.Application.Repositories;


// Also carries the three other fixed/seeded reference lookups the SQL file
// groups with Products (MotorCategories, MotorVehicleClasses, Periods) -
// none of these four have write procs in this version, so one read-only
// interface for all of them avoids four near-empty single-method interfaces.
public interface IProductRepository
{
    Task<StoredProcResult<List<Product>>> GetListAsync();

    Task<StoredProcResult<List<MotorCategory>>> GetMotorCategoriesAsync();

    Task<StoredProcResult<List<MotorVehicleClass>>> GetMotorVehicleClassesAsync();

    Task<StoredProcResult<List<Period>>> GetPeriodsAsync();

    /// <summary>Wraps usp_PolicyLevel_GetList - the DMVIC-style levels MotorVehicleClasses/UnderwriterPolicyLevelNumber reference.</summary>
    Task<StoredProcResult<List<PolicyLevel>>> GetPolicyLevelsAsync();
}
