namespace InsurancePlatform.Api.Contracts.Common;

/// <summary>
/// The one response shape every controller in this API returns, no
/// exceptions. Data is generic so a products list, a login result, a single
/// client record, etc. all fit the same envelope without needing their own
/// wrapper classes. Ref mirrors CorrelationContext.Ref for this request -
/// same value as the X-Correlation-Id response header, just also visible
/// directly in the body so a client (or a person debugging a support
/// ticket) doesn't have to go digging through headers to find it.
/// </summary>
public class ApiResponse<T>
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public T? Data { get; init; }
    public string? Ref { get; init; }

    public static ApiResponse<T> Ok(T? data, string message, string? refValue) =>
        new() { Success = true, Message = message, Data = data, Ref = refValue };

    public static ApiResponse<T> Fail(string message, string? refValue) =>
        new() { Success = false, Message = message, Data = default, Ref = refValue };
}
