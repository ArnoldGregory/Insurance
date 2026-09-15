namespace InsurancePlatform.Application.Payments;

/// <summary>Initiates an M-Pesa STK push (Daraja) via the SCAPI gateway.</summary>
// This only fires the customer's phone prompt - it does NOT confirm the
// payment. "Success" here means Safaricom accepted the push request and
// queued it for the customer's phone; the actual PIN-entry outcome only
// arrives later via Safaricom's own callback, which resolves through
// PaymentsController.UpdateStatus (ChannelService-authenticated), same as
// this project's existing USSD/WhatsApp channel patterns. The Payment row
// this wraps around stays PENDING regardless of what this call returns -
// paying manually via Paybill using the same account reference is always
// still an option if the push fails or the customer never completes it.
public interface IMpesaStkPushService
{
    Task<StkPushResult> InitiatePushAsync(string phoneNumber, decimal amount, string accountReference, string externalRefNumber);
}

public class StkPushResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? MerchantRequestId { get; set; }
    public string? CheckoutRequestId { get; set; }
}
