using InsurancePlatform.Domain.Pricing;

namespace InsurancePlatform.Tests;

public class RateBandCoverageValidatorTests
{
    private static (long, string, List<(decimal, decimal)>) Monarchy(params (decimal, decimal)[] bands) =>
        (3, "Monarch Insurance", bands.ToList());

    [Fact]
    public void ContiguousBands_ReportNoGap()
    {
        var bands = new List<(decimal, decimal)>
        {
            (500000, 1000000),
            (1000001, 1500000),
            (1500001, 2500000)
        };

        var gaps = RateBandCoverageValidator.FindGaps(3, "Monarch Insurance", bands);

        Assert.Empty(gaps);
    }

    [Fact]
    public void HoleInTheMiddle_IsReportedWithExactRange()
    {
        // This is the Old Mutual shape: 3,000,000 through 3,500,000 is unquoted.
        var bands = new List<(decimal, decimal)>
        {
            (500000, 1000000),
            (1000001, 1500000),
            (1500001, 2999999),
            (3500001, 999999999)
        };

        var gaps = RateBandCoverageValidator.FindGaps(12, "Old Mutual Insurance", bands);

        var gap = Assert.Single(gaps);
        Assert.Equal(3000000, gap.GapFrom);
        Assert.Equal(3500000, gap.GapTo);
        Assert.Equal(500001, gap.Width);
        Assert.Equal("Old Mutual Insurance", gap.UnderwriterName);
    }

    [Fact]
    public void AdjacentBands_AreNotTreatedAsAGap()
    {
        // A band ending at 1,000,000 followed by one starting at 1,000,001 is
        // contiguous, not a hole - the boundary value is covered by the second band.
        var bands = new List<(decimal, decimal)>
        {
            (500000, 1000000),
            (1000001, 999999999)
        };

        Assert.Empty(RateBandCoverageValidator.FindGaps(3, "Monarch Insurance", bands));
    }

    [Fact]
    public void UnsortedBands_StillFindTheGap()
    {
        var bands = new List<(decimal, decimal)>
        {
            (3500001, 999999999),
            (1500001, 2999999),
            (1000001, 1500000),
            (500000, 1000000)
        };

        var gap = Assert.Single(RateBandCoverageValidator.FindGaps(12, "Old Mutual Insurance", bands));

        Assert.Equal(3000000, gap.GapFrom);
        Assert.Equal(3500000, gap.GapTo);
    }

    [Fact]
    public void OverlappingBands_AreReported()
    {
        var bands = new List<(decimal, decimal)>
        {
            (500000, 2000000),
            (1500000, 3000000)
        };

        var overlaps = RateBandCoverageValidator.FindOverlaps(9, "MUA Insurance", bands);

        var overlap = Assert.Single(overlaps);
        Assert.Equal(1500000, overlap.OverlapFrom);
        Assert.Equal(2000000, overlap.OverlapTo);
    }

    [Fact]
    public void NoBands_ProducesNoGapReport()
    {
        // An underwriter with zero bands is a seeding problem the caller reports,
        // not a coverage gap, so this must not be reported as one.
        Assert.Empty(RateBandCoverageValidator.FindGaps(99, "New Insurer", new List<(decimal, decimal)>()));
    }

    [Fact]
    public void Validate_AggregatesAcrossUnderwriters()
    {
        var data = new List<(long, string, List<(decimal, decimal)>)>
        {
            (3, "Monarch Insurance", new List<(decimal, decimal)>
            {
                (500000, 1000000),
                (1000001, 999999999)
            }),
            (12, "Old Mutual Insurance", new List<(decimal, decimal)>
            {
                (500000, 1500000),
                (2000001, 999999999)
            })
        };

        var (gaps, overlaps) = RateBandCoverageValidator.Validate(data);

        var gap = Assert.Single(gaps);
        Assert.Equal("Old Mutual Insurance", gap.UnderwriterName);
        Assert.Empty(overlaps);
    }

    [Fact]
    public void GapMessage_NamesTheUnderwriterAndRange()
    {
        var gap = RateBandCoverageValidator
            .FindGaps(12, "Old Mutual Insurance", new List<(decimal, decimal)> { (500000, 1000000), (2000001, 999999999) })
            .Single();

        Assert.Contains("Old Mutual Insurance", gap.ToString());
        Assert.Contains("1,000,001", gap.ToString());
        Assert.Contains("2,000,000", gap.ToString());
    }
}