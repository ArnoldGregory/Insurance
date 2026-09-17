using System.Text.Json;
using System.Text.Json.Serialization;

namespace AmuraWebsite.Services;

// --- Catalog ---
public sealed class VehicleClassDto
{
    public int VehicleClassId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class PeriodDto
{
    public int PeriodId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class ProductDto
{
    public int ProductId { get; set; }
    public string Code { get; set; } = string.Empty;
}

// --- Pricing (TPO) ---
public sealed class TpoPriceOptionDto
{
    public int UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal Price { get; set; }
}

// --- Pricing (Comprehensive) ---
public sealed class ComprehensiveQuoteResponse
{
    public List<ComprehensiveOptionDto> Options { get; set; } = new();
    public Dictionary<string, List<ComprehensiveBenefitDto>> BenefitsByUnderwriter { get; set; } = new();
    public Dictionary<string, List<ComprehensiveLiabilityLimitDto>> LiabilityLimitsByUnderwriter { get; set; } = new();
}

public sealed class ComprehensiveOptionDto
{
    public int UnderwriterId { get; set; }
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal RatePercent { get; set; }
    public decimal MinPremium { get; set; }
    public decimal ValueMin { get; set; }
    public decimal ValueMax { get; set; }
    public decimal BasePremium { get; set; }
    public decimal PvtAmount { get; set; }
    public decimal TotalPremium { get; set; }
}

public sealed class ComprehensiveBenefitDto
{
    public int BenefitId { get; set; }
    public string BenefitCode { get; set; } = string.Empty;
    public string BenefitName { get; set; } = string.Empty;
    public bool IsIncludedInBase { get; set; }
    public decimal DefaultPrice { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
}

public sealed class ComprehensiveLiabilityLimitDto
{
    public int LiabilityLimitId { get; set; }
    public string LimitName { get; set; } = string.Empty;
    public string LimitValue { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
}

// --- Client ---
public sealed class ResolveClientResponseData
{
    public int? ClientId { get; set; }
    public string? MatchStatus { get; set; }
}

public sealed class CreateClientResponseData
{
    public int ClientId { get; set; }
}

// --- Vehicle ---
public sealed class RegisterVehicleResponseData
{
    public int VehicleId { get; set; }
}

// --- Purchase ---
public sealed class CreatePurchaseResponseData
{
    public int PurchaseId { get; set; }
    public string? PolicyNumber { get; set; }
    public string? AccountNumber { get; set; }
    public string? PaybillNumber { get; set; }
}

// --- Payment ---
public sealed class StkPushResponseData
{
    public int? PaymentId { get; set; }
    public bool PushSent { get; set; }
}
