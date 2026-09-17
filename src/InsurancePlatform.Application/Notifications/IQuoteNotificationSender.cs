namespace InsurancePlatform.Application.Notifications;

/// <summary>One structured add-on/rider line carried into the comparison email.</summary>
public class QuoteOfferEmailRider
{
    public string Name { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
    public string? Note { get; set; }
}

/// <summary>
/// One attachment for the offers-comparison email - the underwriter quote
/// document.
///
/// IMPORTANT (found by reading Scapi's own REMAILSERVICE Worker.cs source):
/// Scapi's mail-sending process does NOT accept file content in the
/// request body at all. It reads the "attachment" field as a file path and
/// opens that path directly off whatever disk IT is running on
/// (`new Attachment(path, ...)`) - there's no base64/content field it ever
/// looks at. So this class carries a PATH, not file bytes - see
/// ScapiAttachmentPath below. QuoteRequestsController.SendOffersComparisonEmailAsync
/// is responsible for actually copying the document there before building
/// this object.
/// </summary>
public class QuoteOfferEmailAttachment
{
    public string UnderwriterName { get; set; } = string.Empty;
    public decimal PremiumAmount { get; set; }

    /// <summary>The offer's structured add-on/rider lines; empty when it has none.</summary>
    public List<QuoteOfferEmailRider> AddOns { get; set; } = new();

    /// <summary>Null if this particular offer has no supporting document.</summary>
    public string? DocumentFileName { get; set; }

    /// <summary>
    /// Absolute path to this document as it exists on the SAME machine
    /// Scapi's Worker process reads from (ScapiGateway:OffersAttachmentPath
    /// - see QuoteRequestsController.SendOffersComparisonEmailAsync). Null
    /// if this offer has no document, or the document couldn't be copied
    /// there.
    /// </summary>
    public string? ScapiAttachmentPath { get; set; }
}

/// <summary>
/// Quote-request-lifecycle emails, sent through the same Scapi gateway
/// OtpNotificationSender already uses (IScapiGatewayClient) - see that
/// class for the established pattern this one follows: build a
/// ScapiMessageRoute + JsonObject body, call _gatewayClient.InvokeAsync,
/// treat error_code=="00" as success.
///
/// IMPORTANT: every RequestType/field name below is a PLACEHOLDER. Unlike
/// EMAIL_OTP_BIMA (OtpNotificationSender) and DARAJA_STK
/// (MpesaStkPushService), which mirror a real, already-agreed Scapi
/// contract, nobody has confirmed what these three new email templates are
/// actually called on the Scapi side, or what field names/shapes they
/// expect - per instruction, each gets its own distinct RequestType and a
/// reasonable placeholder body shape (closely modeled on
/// OtpNotificationSender's own fields: recipient_email/subject/
/// customer_name/logo), so the real contract can be dropped in later by
/// editing just this one file - nothing else in the codebase needs to
/// change shape, only these three RequestType strings/JsonObject bodies.
/// </summary>
public interface IQuoteNotificationSender
{
    /// <summary>"We've received your request, please wait for a response" - sent to the requester's own email right after a quote request is successfully created.</summary>
    Task<bool> SendQuoteReceivedEmailAsync(string recipientEmail, string requesterName, string refNo, string productName, string externalRefNumber);

    /// <summary>"A new quote request is waiting - log into the portal to process it" - sent once per active Support/AgentAdmin user's email.</summary>
    Task<bool> SendNewQuoteStaffNotificationAsync(string staffEmail, string refNo, string productName, string requesterName, string externalRefNumber);

    /// <summary>"Here are the offers available - compare and decide" - sent once per batch create/update of quote offers, with every offer's document attached.</summary>
    Task<bool> SendOffersComparisonEmailAsync(string recipientEmail, string requesterName, string refNo, List<QuoteOfferEmailAttachment> offers, string externalRefNumber);
}
