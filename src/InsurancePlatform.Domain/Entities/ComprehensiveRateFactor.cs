namespace InsurancePlatform.Domain.Entities;

/// <summary>A loading/discount line item under a ComprehensiveRateFormula (e.g. anti-theft discount).</summary>
public class ComprehensiveRateFactor
{
    public long FactorId { get; set; }
    public long FormulaId { get; set; }
    public string FactorType { get; set; } = string.Empty;
    public decimal FactorPercent { get; set; }
}

/// <summary>usp_ComprehensiveRateFormula_CalculatePremium's result - base rate + factors, applied to vehicle value.</summary>
public class ComprehensivePremiumResult
{
    public long FormulaId { get; set; }
    public decimal EffectiveRatePercent { get; set; }
    public decimal Premium { get; set; }
}
