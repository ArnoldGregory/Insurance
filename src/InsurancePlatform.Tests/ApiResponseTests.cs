using InsurancePlatform.Api.Contracts.Common;

namespace InsurancePlatform.Tests;

public class ApiResponseTests
{
    [Fact]
    public void Ok_SetsSuccessAndCarriesData_MessageAndRef()
    {
        var response = ApiResponse<object?>.Ok(new { PaymentId = 3 }, "Processed.", "REQ-1");

        Assert.True(response.Success);
        Assert.Equal("Processed.", response.Message);
        Assert.Equal("REQ-1", response.Ref);
        Assert.NotNull(response.Data);
    }

    [Fact]
    public void Fail_SetsFailureAndNullsData()
    {
        var response = ApiResponse<object?>.Fail("No payment found.", "REQ-2");

        Assert.False(response.Success);
        Assert.Equal("No payment found.", response.Message);
        Assert.Equal("REQ-2", response.Ref);
        Assert.Null(response.Data);
    }
}