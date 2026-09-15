namespace InsurancePlatform.Api.Contracts.Payments;

public class CreatePaymentRequest
{
    public long PurchaseId { get; set; }
    public decimal Amount { get; set; }

    /// <summary>MPESA, CARD or BANK.</summary>
    public string Method { get; set; } = string.Empty;
    public string? PayerPhone { get; set; }
    public string? TransactionReference { get; set; }
}

/// <summary>Called from the payment gateway webhook/callback once a payment resolves.</summary>
public class UpdatePaymentStatusRequest
{
    /// <summary>PENDING, SUCCESS or FAILED.</summary>
    public string Status { get; set; } = string.Empty;
    public string? TransactionReference { get; set; }
}

/// <summary>Records a Payment as PENDING and fires an M-Pesa STK push (Daraja) to the customer's phone in one call.</summary>
// AccountReference is caller-supplied (not re-derived server-side) -
// PurchasesController.Create already computed and returned it
// (PurchaseCreateResult.AccountNumber, "{RegNo or ClientIdNo}#{purchase_id}")
// at purchase time; the caller just passes that same value back here.
public class InitiateStkPushRequest
{
    public long PurchaseId { get; set; }
    public decimal Amount { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public string AccountReference { get; set; } = string.Empty;
}
