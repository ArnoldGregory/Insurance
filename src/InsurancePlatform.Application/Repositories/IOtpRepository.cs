using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Application.Repositories;


public interface IOtpRepository
{
   
    Task<StoredProcResult<long?>> CreateAsync(string targetType, long targetId, string destination, string purpose, string otpCodeHash, int expiresMinutes);

    Task<StoredProcResult<long?>> VerifyAsync(string targetType, long targetId, string purpose, string otpCodeHash);
}
