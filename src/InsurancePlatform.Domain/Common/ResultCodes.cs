namespace InsurancePlatform.Domain.Common;
public static class ResultCodes
{
    public const int Success = 0;
    public const int ValidationError = 1;
    public const int NotFound = 2;
    public const int Duplicate = 3;
    public const int BusinessRuleViolation = 4;
    public const int UnexpectedError = 99;
}
