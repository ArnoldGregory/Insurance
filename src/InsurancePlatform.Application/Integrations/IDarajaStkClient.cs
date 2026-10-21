namespace InsurancePlatform.Application.Integrations;

/// <summary>
/// A direct Safaricom Daraja STK push, bypassing the SCAPI message gateway.
/// The SCAPI MPESA route currently fails on its own short-code lookup (its
/// worker throws and the gateway answers error_code 99), and SCAPI is not ours
/// to change - so this is the transport that makes a REAL prompt go out from
/// our own API. Same request shape Daraja documents for
/// /mpesa/stkpush/v1/processrequest, same Basic-auth token dance, same
/// Password = base64(shortcode + passkey + timestamp) encoding.
/// </summary>
// Lives in Application (not Infrastructure) for the same placement reason as
// IScapiGatewayClient: the Application-layer MpesaStkPushService depends on
// it, and Application must not reference Infrastructure.
public interface IDarajaStkClient
{
    Task<DarajaStkResult> PushAsync(DarajaStkRequest request);
}

public class DarajaStkRequest
{
    /// <summary>Customer MSISDN in international form, e.g. 2547XXXXXXXX.</summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>Amount in whole shillings - Daraja rejects fractional amounts.</summary>
    public decimal Amount { get; set; }

    /// <summary>Account reference shown on the customer's phone and in the callback.</summary>
    public string AccountReference { get; set; } = string.Empty;

    /// <summary>Transaction description shown to the customer.</summary>
    public string TransactionDescription { get; set; } = "Insurance Purchase";

    /// <summary>Publicly reachable URL Daraja POSTs the STK result to.</summary>
    public string CallbackUrl { get; set; } = string.Empty;
}

public class DarajaStkResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? MerchantRequestId { get; set; }
    public string? CheckoutRequestId { get; set; }
}
