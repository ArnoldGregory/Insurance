namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Product - the catalog screen's primary list.</summary>
public class ProductItem
{
    public long ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string PricingMethod { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.MotorCategory - the one product hierarchy level the screen lists next to products.</summary>
public class MotorCategoryItem
{
    public long MotorCategoryId { get; set; }
    public long ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.MotorVehicleClass - the TPO pricing dimension.</summary>
public class MotorVehicleClassItem
{
    public long VehicleClassId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool RequiresTonnage { get; set; }
    public long? PolicyLevelId { get; set; }
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Period - the TPO pricing dimension.</summary>
public class PeriodItem
{
    public long PeriodId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? DmvicCode { get; set; }
}

/// <summary>Binding model for the Products & catalog screen - a read-only tabbed view of the products hierarchy.</summary>
public class ProductsIndexViewModel
{
    public List<ProductItem> Products { get; set; } = new();
    public List<MotorCategoryItem> MotorCategories { get; set; } = new();
    public List<MotorVehicleClassItem> VehicleClasses { get; set; } = new();
    public List<PeriodItem> Periods { get; set; } = new();
    public List<PolicyLevelOption> PolicyLevels { get; set; } = new();

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }
}