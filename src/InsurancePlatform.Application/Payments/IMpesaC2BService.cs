namespace InsurancePlatform.Application.Payments;

/// <summary>
/// Registers the Paybill's C2B validation/confirmation URLs with Safaricom
/// Daraja, via SCAPI's DARAJA_REGISTER_URLS route.
/// </summary>
// Daraja only calls the C2B confirmation webhook for a Paybill once its
// URLs have been registered with /mpesa/c2b/v1/registerurl first - without
// this, a customer paying the Paybill manually (the STK push's fallback)
// never reaches MpesaCallbackController.Confirmation. The URL that Daraja
// actually calls is not sent by this call at all: SCAPI's RMPESAMANAGER
// reads it from the short code's own mpesa_call_back_url column in the
// scapi DB and registers that, so this only ever selects the short code and
// the response type. That DB value is the real place to point at the
// insurance platform's /api/mpesa/callback/confirmation endpoint.
public interface IMpesaC2BService
{
    Task<C2BRegisterResult> RegisterUrlsAsync(string responseType);
}

public class C2BRegisterResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}
