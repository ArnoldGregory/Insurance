using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Payments;

/// <summary>
/// Composes the DARAJA_STK message body on top of the generic
/// IScapiGatewayClient - same shape as OtpNotificationSender composing
/// EMAIL_OTP_BIMA/SINGLE bodies on the same gateway client. Reads
/// Mpesa:BusinessShortCode/CallbackUrl straight off IConfiguration
/// (matches OtpNotificationSender's ScapiGateway:LogoUrl approach) rather
/// than a bound settings class, since these are two plain strings, not a
/// typed HttpClient configuration.
/// </summary>
public class MpesaStkPushService : IMpesaStkPushService
{
    private readonly IScapiGatewayClient _gatewayClient;
    private readonly string _businessShortCode;
    private readonly string _callbackUrl;

    public MpesaStkPushService(IScapiGatewayClient gatewayClient, IConfiguration configuration)
    {
        _gatewayClient = gatewayClient;
        _businessShortCode = configuration["Mpesa:BusinessShortCode"] ?? string.Empty;
        _callbackUrl = configuration["Mpesa:CallbackUrl"] ?? string.Empty;
    }

    public async Task<StkPushResult> InitiatePushAsync(string phoneNumber, decimal amount, string accountReference, string externalRefNumber)
    {
        var route = new ScapiMessageRoute
        {
            Interface = "MPESA",
            RequestType = "DARAJA_STK",
            ExternalRefNumber = externalRefNumber
        };

        var body = new JsonObject
        {
            ["business_short_code"] = _businessShortCode,
            ["phone_number"] = NormalizeKenyanPhoneNumber(phoneNumber),
            // Daraja STK push amounts are whole shillings, no cents - round
            // rather than truncate so a premium like 8500.50 doesn't
            // silently undercharge by a few cents.
            ["amount"] = Math.Round(amount, 0, MidpointRounding.AwayFromZero).ToString("F0"),
            ["account_reference"] = accountReference,
            ["transaction_desc"] = "Insurance Purchase",
            ["callback_url"] = _callbackUrl
        };

        var response = await _gatewayClient.InvokeAsync(route, body);

        if (response is null)
        {
            return new StkPushResult { Success = false, Message = "Could not reach the payment gateway - please try again shortly." };
        }

        var errorCode = response["error_code"]?.ToString();
        var errorDesc = response["error_desc"] as JsonObject;
        var responseCode = errorDesc?["ResponseCode"]?.ToString();
        var responseDescription = errorDesc?["ResponseDescription"]?.ToString()
            ?? errorDesc?["CustomerMessage"]?.ToString()
            ?? "Unknown gateway response.";

        // Two success gates, matching the legacy STK push flow this is
        // ported from: error_code=="00" is SCAPI's own gateway-level
        // success, ResponseCode=="0" is Daraja's own "push accepted"
        // code nested one level down inside error_desc. Both must pass.
        if (errorCode != "00" || responseCode != "0")
        {
            return new StkPushResult { Success = false, Message = responseDescription };
        }

        return new StkPushResult
        {
            Success = true,
            Message = "Payment received successfully. Kindly check your phone to key in your PIN to finish payment.",
            MerchantRequestId = errorDesc?["MerchantRequestID"]?.ToString(),
            CheckoutRequestId = errorDesc?["CheckoutRequestID"]?.ToString()
        };
    }

    private static string NormalizeKenyanPhoneNumber(string phoneNumber)
    {
        var digitsOnly = Regex.Replace(phoneNumber, @"\D", string.Empty);
        var lastNineDigits = digitsOnly.Length >= 9 ? digitsOnly[^9..] : digitsOnly;
        return "254" + lastNineDigits;
    }
}
