using InsurancePlatform.Application.Certificates;

namespace InsurancePlatform.Tests;

public class DmvicVehicleTypeMappingTests
{
    [Theory]
    [InlineData("PRIVATE", "issuance_type_c_cert", "Private Car")]
    [InlineData("private", "issuance_type_c_cert", "Private Car")]
    [InlineData("PSV-BUS", "issuance_type_a_cert", "6")]
    [InlineData("PSV-MATATU", "issuance_type_a_cert", "1")]
    [InlineData("PSV-TAXI / TUK TUK", "issuance_type_a_cert", "8")]
    [InlineData("PSV-PRIVATE HIRE/Uber", "issuance_type_a_cert", "1")]
    [InlineData("MOTOR COMMERCIAL:OWN GOODS", "issuance_type_b_cert", "1")]
    [InlineData("MOTOR COMMERCIAL:GENERAL", "issuance_type_b_cert", "2")]
    [InlineData("MOTOR COMMERCIAL:INSTITUTION", "issuance_type_b_cert", "3")]
    [InlineData("MOTOR COMMERCIAL:Tankers & Specified Trailer", "issuance_type_b_cert", "5")]
    [InlineData("MOTOR COMMERCIAL:Prime Mover", "issuance_type_b_cert", "4")]
    [InlineData("MOTOR COMMERCIAL:Trailer", "issuance_type_b_cert", "4")]
    [InlineData("MOTOR COMMERCIAL:TRACTOR", "issuance_type_b_cert", "4")]
    [InlineData("MOTORCYCLE:PRIVATE", "issuance_type_d_cert", "4")]
    [InlineData("MOTORCYCLE:PSV", "issuance_type_d_cert", "9")]
    public void KnownVehicleClass_ResolvesToExpectedCertificateType(string vehicleType, string expectedRequestType, string expectedCertificate)
    {
        var options = new DmvicOptions();

        var resolved = options.TryResolveVehicleType(vehicleType, out var requestType, out var certificate);

        Assert.True(resolved);
        Assert.Equal(expectedRequestType, requestType);
        Assert.Equal(expectedCertificate, certificate);
    }

    [Fact]
    public void UnknownVehicleClass_RefusesIssuance()
    {
        var options = new DmvicOptions();

        var resolved = options.TryResolveVehicleType("SPACE ROCKET", out _, out _);

        Assert.False(resolved);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void BlankVehicleType_UsesConfiguredDefault(string? vehicleType)
    {
        var options = new DmvicOptions();

        var resolved = options.TryResolveVehicleType(vehicleType, out var requestType, out var certificate);

        Assert.True(resolved);
        Assert.Equal(options.RequestType, requestType);
        Assert.Equal(options.TypeOfCertificate, certificate);
    }

    [Fact]
    public void ConfigOverride_WinsOverBuiltInMap()
    {
        var options = new DmvicOptions();
        options.VehicleTypeMap["PSV-MATATU"] = "issuance_type_a_cert|99";

        var resolved = options.TryResolveVehicleType("PSV-MATATU", out var requestType, out var certificate);

        Assert.True(resolved);
        Assert.Equal("issuance_type_a_cert", requestType);
        Assert.Equal("99", certificate);
    }

    [Fact]
    public void TypeOfCover_Default_IsNtsaComprehensiveCategoryCode()
    {
        var options = new DmvicOptions();

        Assert.Equal("100", options.TypeOfCover);
    }
}
