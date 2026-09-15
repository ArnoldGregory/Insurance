using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Application.Repositories;

public interface IRoleRepository
{
    /// <summary>
    /// The permission codes (e.g. PURCHASE_ON_BEHALF, MANAGE_PRICING - see
    /// PermissionCodes constants) granted to a role, via usp_Role_GetPermissions.
    /// AuthService embeds these directly into the JWT as claims at login time,
    /// so every later request's [Authorize(Policy = ...)] check reads them off
    /// the token instead of hitting the database again.
    /// </summary>
    Task<StoredProcResult<List<string>>> GetPermissionCodesAsync(long roleId);
}
