using System.Text.Json.Nodes;
using InsurancePlatform.Application.Integrations;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Notifications;

/// <summary>
/// See IQuoteNotificationSender's own doc comment first - every
/// RequestType/field name in the three methods below is a placeholder,
/// not a confirmed Scapi contract. Structured exactly like
/// OtpNotificationSender (same _gatewayClient/_emailLogoUrl fields, same
/// "error_code == 00" success check) so swapping in the real contract
/// later is a small, contained diff.
/// </summary>
public class QuoteNotificationSender : IQuoteNotificationSender
{
    private readonly IScapiGatewayClient _gatewayClient;
    private readonly string _emailLogoUrl;

    public QuoteNotificationSender(IScapiGatewayClient gatewayClient, IConfiguration configuration)
    {
        _gatewayClient = gatewayClient;
        _emailLogoUrl = configuration["ScapiGateway:LogoUrl"] ?? string.Empty;
    }

    public async Task<bool> SendQuoteReceivedEmailAsync(string recipientEmail, string requesterName, string refNo, string productName, string externalRefNumber)
    {
        // PLACEHOLDER RequestType - see IQuoteNotificationSender's top comment.
        var route = new ScapiMessageRoute
        {
            Interface = "SMS",
            RequestType = "EMAIL_QUOTE_RECEIVED_CLIENT",
            ExternalRefNumber = externalRefNumber
        };

        var body = new JsonObject
        {
            ["recipient_email"] = recipientEmail,
            ["subject"] = $"We've received your {productName} quote request ({refNo})",
            ["customer_name"] = requesterName,
            ["ref_no"] = refNo,
            ["product_name"] = productName,
            ["body_text"] = $"Hi {requesterName}, thank you for your {productName} quote request (reference {refNo}). " +
                             "We've received it and are working on it - please wait while we get back to you with pricing options.",
            ["attachment"] = string.Empty,
            ["logo"] = _emailLogoUrl
        };

        var response = await _gatewayClient.InvokeAsync(route, body);
        return response?["error_code"]?.ToString() == "00";
    }

    public async Task<bool> SendNewQuoteStaffNotificationAsync(string staffEmail, string refNo, string productName, string requesterName, string externalRefNumber)
    {
        // PLACEHOLDER RequestType - see IQuoteNotificationSender's top comment.
        var route = new ScapiMessageRoute
        {
            Interface = "SMS",
            RequestType = "EMAIL_QUOTE_NEW_STAFF_NOTIFY",
            ExternalRefNumber = externalRefNumber
        };

        var body = new JsonObject
        {
            ["recipient_email"] = staffEmail,
            ["subject"] = $"New {productName} quote request ({refNo}) needs processing",
            ["ref_no"] = refNo,
            ["product_name"] = productName,
            ["requester_name"] = requesterName,
            ["customer_name"] = requesterName,
            ["body_text"] = $"A new {productName} quote request (reference {refNo}) from {requesterName} is waiting in the queue - " +
                             "log into the Admin Portal to assign and process it.",
            ["attachment"] = string.Empty,
            ["logo"] = _emailLogoUrl
        };

        var response = await _gatewayClient.InvokeAsync(route, body);
        return response?["error_code"]?.ToString() == "00";
    }

    public async Task<bool> SendOffersComparisonEmailAsync(string recipientEmail, string requesterName, string refNo, List<QuoteOfferEmailAttachment> offers, string externalRefNumber)
    {
        // PLACEHOLDER RequestType - see IQuoteNotificationSender's top comment.
        var route = new ScapiMessageRoute
        {
            Interface = "SMS",
            RequestType = "EMAIL_QUOTE_OFFERS_COMPARISON",
            ExternalRefNumber = externalRefNumber
        };

        var offersArray = new JsonArray();
        var attachmentPaths = new List<string>();

        foreach (var offer in offers)
        {
            offersArray.Add(new JsonObject
            {
                ["underwriter_name"] = offer.UnderwriterName,
                // Stringified like MpesaStkPushService's own "amount" field -
                // sidesteps any culture/formatting ambiguity in how a raw
                // decimal serializes to JSON (invariant "F2", not
                // locale-dependent), same reasoning as that class's comment.
                ["premium_amount"] = offer.PremiumAmount.ToString("F2", System.Globalization.CultureInfo.InvariantCulture),
                ["document_file_name"] = offer.DocumentFileName ?? string.Empty
            });

            if (!string.IsNullOrEmpty(offer.ScapiAttachmentPath))
            {
                attachmentPaths.Add(offer.ScapiAttachmentPath);
            }
        }

        var body = new JsonObject
        {
            ["recipient_email"] = recipientEmail,
            ["subject"] = $"Your {refNo} quote offers are ready - please compare and decide",
            ["customer_name"] = requesterName,
            ["ref_no"] = refNo,
            ["offers"] = offersArray,
            ["body_text"] = $"Hi {requesterName}, here are the offers available for your quote request (reference {refNo}). " +
                             "Kindly compare them and let us know which one you'd like to go with. The supporting documents, where available, are attached.",
            // Scapi's REMAILSERVICE Worker.cs splits this field on ';' and
            // attaches each path it finds (own file, confirmed by reading
            // its source) - one path per offer document that has one.
            // There is no "attachments" (plural/base64) field - Worker.cs
            // never reads anything by that name, so it was silently
            // dropped every time this used to be sent.
            ["attachment"] = string.Join(";", attachmentPaths),
            ["logo"] = _emailLogoUrl
        };

        var response = await _gatewayClient.InvokeAsync(route, body);
        return response?["error_code"]?.ToString() == "00";
    }
}
