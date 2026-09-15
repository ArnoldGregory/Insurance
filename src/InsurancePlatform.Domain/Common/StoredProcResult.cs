namespace InsurancePlatform.Domain.Common;


public class StoredProcResult
{
    public int ResultCode { get; init; }
    public string ResultMessage { get; init; } = string.Empty;
    public bool IsSuccess => ResultCode == ResultCodes.Success;
    public bool IsValidationError => ResultCode == ResultCodes.ValidationError;
    public bool IsNotFound => ResultCode == ResultCodes.NotFound;
    public bool IsDuplicate => ResultCode == ResultCodes.Duplicate;
    public bool IsBusinessRuleViolation => ResultCode == ResultCodes.BusinessRuleViolation;
}
public class StoredProcResult<T> : StoredProcResult
{
    public T? Data { get; init; }
}
