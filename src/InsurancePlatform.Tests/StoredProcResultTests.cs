using InsurancePlatform.Domain.Common;

namespace InsurancePlatform.Tests;

public class StoredProcResultTests
{
    [Fact]
    public void IsSuccess_TrueOnlyWhenResultCodeIsZero()
    {
        Assert.True(new StoredProcResult { ResultCode = ResultCodes.Success }.IsSuccess);
        Assert.False(new StoredProcResult { ResultCode = ResultCodes.ValidationError }.IsSuccess);
        Assert.False(new StoredProcResult { ResultCode = ResultCodes.UnexpectedError }.IsSuccess);
    }

    [Fact]
    public void SpecialtyFlags_MapToTheirCodes()
    {
        Assert.True(new StoredProcResult { ResultCode = ResultCodes.ValidationError }.IsValidationError);
        Assert.True(new StoredProcResult { ResultCode = ResultCodes.NotFound }.IsNotFound);
        Assert.True(new StoredProcResult { ResultCode = ResultCodes.Duplicate }.IsDuplicate);
        Assert.True(new StoredProcResult { ResultCode = ResultCodes.BusinessRuleViolation }.IsBusinessRuleViolation);
    }

    [Fact]
    public void GenericResult_ExposesData()
    {
        var result = new StoredProcResult<long?> { ResultCode = ResultCodes.Success, Data = 7 };
        Assert.True(result.IsSuccess);
        Assert.Equal(7, result.Data);

        var empty = new StoredProcResult<long?> { ResultCode = ResultCodes.NotFound, Data = null };
        Assert.True(empty.IsNotFound);
        Assert.Null(empty.Data);
    }
}