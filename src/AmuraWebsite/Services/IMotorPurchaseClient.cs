namespace AmuraWebsite.Services;

/// <summary>
/// Covers the real-money Motor guest journey confirmed in the
/// "20. Website - Full Client Journey" Postman folder: TPO price
/// comparison, client resolve-or-create, vehicle registration, purchase
/// creation, and M-Pesa STK push. This is deliberately a separate client
/// from IInsurancePlatformClient (the 5 simple quote-request forms) since
/// this flow is fundamentally different — multi-step, stateful, and
/// involves an actual payment rather than a single lead-capture POST.
///
/// Every method returns null (or false for the boolean check) rather than
/// throwing — callers are responsible for showing the person a clear
/// "something went wrong, please try again" message. Nothing here should
/// ever silently fall back the way the 5 quote forms do, since this
/// involves real money and a real vehicle record — a failure must be
/// visible, not swallowed.
/// </summary>
public interface IMotorPurchaseClient
{
    bool IsConfigured { get; }

    Task<List<VehicleClassDto>?> GetVehicleClassesAsync(CancellationToken ct = default);
    Task<List<PeriodDto>?> GetPeriodsAsync(CancellationToken ct = default);
    Task<int?> GetMotorProductIdAsync(CancellationToken ct = default);

    Task<List<TpoPriceOptionDto>?> GetTpoPricingAsync(
        int vehicleClassId, int periodId, int carryCapacity, CancellationToken ct = default);

    Task<ComprehensiveQuoteResponse?> GetComprehensiveCompareAsync(
        decimal vehicleValue, CancellationToken ct = default);

    Task<ResolveClientResponseData?> ResolveClientAsync(string idNo, CancellationToken ct = default);

    Task<int?> CreateClientAsync(
        string idNo, string fullName, DateTime dob, string email, string phone,
        string? address, string? kraPin, CancellationToken ct = default);

    Task<int?> RegisterVehicleAsync(
        int clientId, string make, string model, string regNo, string chassisNo, string engineNo,
        int yearOfManufacture, string vehicleType, string bodyType, string fuelType,
        string cubicCapacity, string color, string logbook, CancellationToken ct = default);

    Task<CreatePurchaseResponseData?> CreatePurchaseAsync(
        int productId, int clientId, int underwriterId, decimal premiumAmount, int periodId,
        DateTime startDate, int vehicleId, int licensedToCarry, CancellationToken ct = default);

    Task<CreatePurchaseResponseData?> CreateComprehensivePurchaseAsync(
        int productId, int clientId, int underwriterId, decimal premiumAmount, int periodId,
        DateTime startDate, int vehicleId, decimal vehicleValue, CancellationToken ct = default);

    Task<StkPushResponseData?> InitiatePaymentAsync(
        int purchaseId, decimal amount, string phoneNumber, string accountReference, CancellationToken ct = default);
}
