namespace InsurancePlatform.Domain.Pricing;

/// <summary>A gap in an underwriter's rate band coverage.</summary>
public class RateBandGap
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    /// <summary>First vehicle value with no band covering it (inclusive).</summary>
    public decimal GapFrom { get; set; }

    /// <summary>Last vehicle value with no band covering it (inclusive).</summary>
    public decimal GapTo { get; set; }

    public decimal Width => GapTo - GapFrom + 1;

    public override string ToString() =>
        $"{UnderwriterName} has no rate band covering vehicle values " +
        $"{GapFrom:N0} to {GapTo:N0} ({Width:N0} wide)";
}

/// <summary>An overlap where two bands both cover the same vehicle value.</summary>
public class RateBandOverlap
{
    public long UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal OverlapFrom { get; set; }
    public decimal OverlapTo { get; set; }

    public override string ToString() =>
        $"{UnderwriterName} has overlapping rate bands covering vehicle values " +
        $"{OverlapFrom:N0} to {OverlapTo:N0}";
}

/// <summary>
/// Detects coverage holes in comprehensive rate bands.
///
/// The pricing proc selects bands with a plain BETWEEN, so any value not
/// covered by a band makes that underwriter silently drop out of the compare
/// response. Nothing errors, the customer just sees fewer insurers quoted.
/// This turns that silent failure into a report a test or startup check can act on.
/// </summary>
public static class RateBandCoverageValidator
{
    /// <summary>
    /// Finds ranges of vehicle value that no band covers for a given underwriter,
    /// between the lowest and highest configured value. Bands should be sorted by
    /// value_min and must not overlap for this to be meaningful.
    /// </summary>
    public static IReadOnlyList<RateBandGap> FindGaps(
        long underwriterId,
        string underwriterName,
        IEnumerable<(decimal ValueMin, decimal ValueMax)> bands)
    {
        var gaps = new List<RateBandGap>();
        var ordered = bands
            .Where(b => b.ValueMax >= b.ValueMin)
            .OrderBy(b => b.ValueMin)
            .ToList();

        if (ordered.Count == 0)
        {
            // No bands at all means the underwriter can never be quoted.
            return gaps;
        }

        for (var i = 1; i < ordered.Count; i++)
        {
            var previousMax = ordered[i - 1].ValueMax;
            var currentMin = ordered[i].ValueMin;

            if (currentMin > previousMax + 1)
            {
                gaps.Add(new RateBandGap
                {
                    UnderwriterId = underwriterId,
                    UnderwriterName = underwriterName,
                    GapFrom = previousMax + 1,
                    GapTo = currentMin - 1
                });
            }
        }

        return gaps;
    }

    /// <summary>
    /// Finds ranges where two or more bands for the same underwriter both match.
    /// An overlap means the stored proc returns duplicate rows for one underwriter,
    /// which the UI renders as the same insurer quoted twice.
    /// </summary>
    public static IReadOnlyList<RateBandOverlap> FindOverlaps(
        long underwriterId,
        string underwriterName,
        IEnumerable<(decimal ValueMin, decimal ValueMax)> bands)
    {
        var overlaps = new List<RateBandOverlap>();
        var ordered = bands
            .Where(b => b.ValueMax >= b.ValueMin)
            .OrderBy(b => b.ValueMin)
            .ToList();

        for (var i = 1; i < ordered.Count; i++)
        {
            var previous = ordered[i - 1];
            var current = ordered[i];

            if (current.ValueMin <= previous.ValueMax)
            {
                overlaps.Add(new RateBandOverlap
                {
                    UnderwriterId = underwriterId,
                    UnderwriterName = underwriterName,
                    OverlapFrom = current.ValueMin,
                    OverlapTo = Math.Min(previous.ValueMax, current.ValueMax)
                });
            }
        }

        return overlaps;
    }

    /// <summary>
    /// Runs both checks across every underwriter. Only underwriters present in
    /// <paramref name="bandsByUnderwriter"/> are examined - an underwriter with no
    /// bands at all is a data-seeding question, not a coverage gap, and is reported
    /// by the caller rather than treated as an error here.
    /// </summary>
    public static (IReadOnlyList<RateBandGap> Gaps, IReadOnlyList<RateBandOverlap> Overlaps) Validate(
        IEnumerable<(long UnderwriterId, string UnderwriterName, List<(decimal ValueMin, decimal ValueMax)> Bands)> bandsByUnderwriter)
    {
        var gaps = new List<RateBandGap>();
        var overlaps = new List<RateBandOverlap>();

        foreach (var (underwriterId, underwriterName, bands) in bandsByUnderwriter)
        {
            gaps.AddRange(FindGaps(underwriterId, underwriterName, bands));
            overlaps.AddRange(FindOverlaps(underwriterId, underwriterName, bands));
        }

        return (gaps, overlaps);
    }
}