using InsurancePlatform.Application.Certificates;
using InsurancePlatform.Infrastructure.Certificates;

namespace InsurancePlatform.Tests;

public class UnderwriterIntegrationOptionsTests
{
    [Theory]
    [InlineData("Direct Line Assurance", "directline", true)]
    [InlineData("DIRECTLINE", "directline", true)]
    [InlineData("AMACO Insurance", "amaco", true)]
    [InlineData("Definite Assurance", "definite", true)]
    [InlineData("APA Insurance Limited", "directline", false)]
    [InlineData(null, "directline", false)]
    [InlineData("Direct Line Assurance", "", false)]
    public void NameMatches_IgnoresCaseAndSpaces(string? underwriterName, string nameContains, bool expected)
    {
        Assert.Equal(expected, UnderwriterIntegrationOptions.NameMatches(underwriterName, nameContains));
    }

    [Theory]
    [InlineData(365, "1")]
    [InlineData(182, "2")]
    [InlineData(30, "12")]
    [InlineData(14, "26")]
    [InlineData(7, "52")]
    [InlineData(3, null)]
    public void DirectLinePeriodCode_MatchesBimadlineCodes(int durationDays, string? expected)
    {
        Assert.Equal(expected, DirectLineIntegrationOptions.PeriodCode(durationDays));
    }

    [Fact]
    public void DirectLineVehicleType_UsesMapThenDefault()
    {
        var options = new DirectLineIntegrationOptions
        {
            VehicleTypeMap = new Dictionary<string, string> { ["PRIVATE"] = "7" },
            DefaultVehicleType = ""
        };

        Assert.True(options.TryResolveVehicleType("private", out var mapped));
        Assert.Equal("7", mapped);
        Assert.False(options.TryResolveVehicleType("PSV-MATATU", out _));

        options.DefaultVehicleType = "1";
        Assert.True(options.TryResolveVehicleType("PSV-MATATU", out var fallback));
        Assert.Equal("1", fallback);
    }

    [Fact]
    public void AllIntegrationsDisabledByDefault()
    {
        Assert.False(new UnderwriterIntegrationOptions().AnyEnabled);
    }

    [Fact]
    public void CertificateFileName_IsDeterministicAndSafe()
    {
        var store = new LocalCertificateFileStore(
            new HttpClient(),
            new Microsoft.Extensions.Configuration.ConfigurationBuilder().Build(),
            new NullLogger());

        Assert.Equal("42_C27617866.pdf", store.GetFileName(42, "C27617866"));
        Assert.Equal("42_etcpasswd.pdf", store.GetFileName(42, "../etc/passwd"));
    }

    private sealed class NullLogger : InsurancePlatform.Domain.Common.ILoggerManager
    {
        public void LogInfo(string message) { }
        public void LogWarn(string message) { }
        public void LogDebug(string message) { }
        public void LogError(string message) { }
        public void LogError(string message, Exception exception) { }
    }
}
