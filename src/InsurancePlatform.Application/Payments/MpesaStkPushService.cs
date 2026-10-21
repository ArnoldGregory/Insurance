using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Domain.Common;
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
    private const int MaxAttempts = 3;

    private readonly IScapiGatewayClient _gatewayClient;
    private readonly IDarajaStkClient _darajaClient;
    private readonly ILoggerManager _logger;
    private readonly string _businessShortCode;
    private readonly string _callbackUrl;
    private readonly bool _useDirectDaraja;

    public MpesaStkPushService(
        IScapiGatewayClient gatewayClient,
        IDarajaStkClient darajaClient,
        IConfiguration configuration,
        ILoggerManager logger)
    {
        _gatewayClient = gatewayClient;
        _darajaClient = darajaClient;
        _logger = logger;
        _businessShortCode = configuration["Mpesa:BusinessShortCode"] ?? string.Empty;
        _callbackUrl = configuration["Mpesa:CallbackUrl"] ?? string.Empty;

        // "Daraja" sends the STK push straight to Safaricom, bypassing the
        // SCAPI message gateway; anything else (default) keeps using SCAPI.
        // The switch exists because SCAPI's own MPESA route fails on its
        // short-code lookup and SCAPI is not ours to fix - but the Daraja
        // credentials are ours, so the direct path is the one that can
        // actually put a real prompt on a customer's phone today.
        _useDirectDaraja = string.Equals(
            configuration["Mpesa:Transport"], "Daraja", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<StkPushResult> InitiatePushAsync(string phoneNumber, decimal amount, string accountReference, string externalRefNumber)
    {
        if (_useDirectDaraja)
        {
            return await PushDirectAsync(phoneNumber, amount, accountReference);
        }

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

        JsonObject? response = null;
        var usedRef = externalRefNumber;

        // SCAPI is a message gateway: it can fail for reasons that have
        // nothing to do with the request itself (its own worker throwing,
        // a queue hiccup, a dropped connection). Its error 99 is literally
        // "An unexpected error occurred. Please retry." - so retry, but with
        // a FRESH external_ref_number each attempt: SCAPI rejects a ref it
        // has already processed ("Reference number already processed"), so
        // replaying the same one would fail for a different reason.
        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            usedRef = attempt == 1 ? externalRefNumber : $"{externalRefNumber}-r{attempt}";

            var route = new ScapiMessageRoute
            {
                Interface = "MPESA",
                RequestType = "DARAJA_STK",
                ExternalRefNumber = usedRef
            };

            response = await _gatewayClient.InvokeAsync(route, body);

            if (response is not null && !IsTransientGatewayFailure(response))
            {
                break;
            }

            if (attempt < MaxAttempts)
            {
                _logger.LogWarn($"STK push attempt {attempt}/{MaxAttempts} did not get a usable answer from SCAPI (ref={usedRef}) - retrying.");
                await Task.Delay(TimeSpan.FromSeconds(2 * attempt));
            }
        }

        if (response is null)
        {
            return new StkPushResult
            {
                Success = false,
                Message = $"Could not reach the payment gateway after {MaxAttempts} attempts (reference {usedRef}) - please try again shortly."
            };
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
                Message = "Payment request sent. Kindly check your phone and enter your M-Pesa PIN to complete the payment.",
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

        var detail = string.IsNullOrWhiteSpace(description) ? "Gateway rejected the request." : description;

        // A gateway-level failure (SCAPI's own error_code) carries no useful
        // text on its own - "An unexpected error occurred. Please retry." says
        // nothing about which request failed. Prefix it with SCAPI's error
        // code and the external reference we sent, so the SCAPI server log
        // can be found by grepping for that reference.
        var message = errorCode == "00"
            ? detail
            : $"SCAPI error {errorCode} (reference {usedRef}, short code {_businessShortCode}): {detail}";

        return new StkPushResult
        {
            Success = false,
            Message = message,
            MerchantRequestId = errorDesc is JsonObject failJo ? failJo["MerchantRequestID"]?.ToString() : null,
            CheckoutRequestId = errorDesc is JsonObject failCo ? failCo["CheckoutRequestID"]?.ToString() : null
        };
    }

    /// <summary>
    /// Sends the STK push straight to Safaricom Daraja, with no SCAPI in
    /// the middle. Same outcome as the SCAPI path - a prompt on the
    /// customer's phone - but the request goes to Daraja itself, so it does
    /// not depend on the SCAPI gateway's own short-code/credential lookups
    /// working. Daraja answers with its own ResponseCode, and the
    /// CheckoutRequestID it returns is the reference Daraja echoes back in
    /// the callback that resolves the payment.
    /// </summary>
    private async Task<StkPushResult> PushDirectAsync(string phoneNumber, decimal amount, string accountReference)
    {
        var result = await _darajaClient.PushAsync(new DarajaStkRequest
        {
            PhoneNumber = NormalizeKenyanPhoneNumber(phoneNumber),
            Amount = amount,
            AccountReference = accountReference,
            TransactionDescription = "Insurance Purchase",
            CallbackUrl = _callbackUrl
        });

        return new StkPushResult
        {
            Success = result.Success,
            Message = result.Message,
            MerchantRequestId = result.MerchantRequestId,
            CheckoutRequestId = result.CheckoutRequestId
        };
    }

    /// <summary>
    /// True when SCAPI's answer carries no verdict of its own - a null
    /// response (token/transport failure) or its catch-all error_code 99,
    /// which is the code its own controller returns when something inside
    /// the gateway threw. Both are worth another attempt. A 00 (with Daraja
    /// rejecting it) or a 01 (a real, explained rejection such as a duplicate
    /// reference) is a final answer and must not be retried.
    /// </summary>
    private static bool IsTransientGatewayFailure(JsonObject response)
    {
        return response["error_code"]?.ToString() == "99";
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
