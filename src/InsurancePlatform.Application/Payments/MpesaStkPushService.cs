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
        var errorDesc = response["error_desc"];

        // Two success gates, matching the legacy STK push flow this is
        // ported from: error_code=="00" is SCAPI's own gateway-level
        // success, ResponseCode=="0" is Daraja's own "push accepted"
        // code nested one level down inside error_desc. Both must pass.
        if (errorCode == "00" && errorDesc is JsonObject gj && gj["ResponseCode"]?.ToString() == "0")
        {
            return new StkPushResult
            {
                Success = true,
                Message = "Payment received successfully. Kindly check your phone to key in your PIN to finish payment.",
                MerchantRequestId = gj["MerchantRequestID"]?.ToString(),
                CheckoutRequestId = gj["CheckoutRequestID"]?.ToString()
            };
        }

        // Failure path - surface the REAL reason instead of a generic
        // message. SCAPI's failure shapes are inconsistent:
        //  * JsonObject  - either Daraja's own rejection (ResponseCode/
        //                  ResponseDescription/CustomerMessage) or SCAPI's
        //                  { error_desc: { Message: ... } } style.
        //  * JsonArray   - SCAPI's RMPESAMANAGER wraps a server-side
        //                  exception as [{ "exception": "<stacktrace>" }]
        //                  (e.g. an unregistered business_short_code makes
        //                  its DB lookup throw), so pull text out of it.
        //  * plain value - SCAPI sometimes returns a flat string.
        var description = errorDesc switch
        {
            JsonObject jo =>
                jo["ResponseDescription"]?.ToString()
                ?? jo["CustomerMessage"]?.ToString()
                ?? jo["Message"]?.ToString()
                ?? jo["error_desc"]?.ToString()
                ?? "Gateway rejected the request.",
            JsonArray arr when arr[0] is JsonObject first =>
                ExtractExceptionText(first),
            JsonArray arr => $"Gateway error: {arr.ToJsonString()}",
            null => "Gateway rejected the request.",
            _ => errorDesc.ToString()
        };

        return new StkPushResult
        {
            Success = false,
            Message = string.IsNullOrWhiteSpace(description) ? "Gateway rejected the request." : description,
            MerchantRequestId = errorDesc is JsonObject failJo ? failJo["MerchantRequestID"]?.ToString() : null,
            CheckoutRequestId = errorDesc is JsonObject failCo ? failCo["CheckoutRequestID"]?.ToString() : null
        };
    }

    /// <summary>
    /// SCAPI's RMPESAMANAGER exception envelope is
    /// [{ "exception": "\n   at ..." }] - a stack trace, not a friendly
    /// line. Keep the first meaningful line (usually the message the
    /// exception started with is buried in it, so grab the first non-blank
    /// line and cap it) rather than returning the whole trace to a client.
    /// </summary>
    private static string? ExtractExceptionText(JsonObject element)
    {
        var trace = element["exception"]?.ToString();
        if (string.IsNullOrWhiteSpace(trace))
        {
            return "Gateway processing error.";
        }

        foreach (var line in trace.Split(Environment.NewLine, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (!string.IsNullOrWhiteSpace(line))
            {
                return line.Length <= 300 ? line : line[..300] + "...";
            }
        }

        return "Gateway processing error.";
    }

    private static string NormalizeKenyanPhoneNumber(string phoneNumber)
    {
        var digitsOnly = Regex.Replace(phoneNumber, @"\D", string.Empty);
        var lastNineDigits = digitsOnly.Length >= 9 ? digitsOnly[^9..] : digitsOnly;
        return "254" + lastNineDigits;
    }
}
