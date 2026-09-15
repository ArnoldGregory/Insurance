using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Domain.Common;
using MySqlConnector;

namespace InsurancePlatform.Data.Repositories;

public class RoleRepository : IRoleRepository
{
    private readonly IStoredProcedureExecutor _executor;

    public RoleRepository(IStoredProcedureExecutor executor)
    {
        _executor = executor;
    }

    public Task<StoredProcResult<List<string>>> GetPermissionCodesAsync(long roleId)
    {
        var parameters = new List<MySqlParameter>
        {
            new("p_role_id", roleId)
        };

        // usp_Role_GetPermissions returns permission_id, code, description
        // per row - we only need "code" (matches PermissionCodes constants).
        return _executor.ExecuteQueryAsync(
            "usp_Role_GetPermissions",
            parameters,
            reader => reader.GetString("code"));
    }
}
