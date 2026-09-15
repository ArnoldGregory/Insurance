using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using InsurancePlatform.Application.Integrations;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Notifications;


public class OtpNotificationSender : IOtpNotificationSender
{
    private readonly IScapiGatewayClient _gatewayClient;
    private readonly string _emailLogoUrl;

    public OtpNotificationSender(IScapiGatewayClient gatewayClient, IConfiguration configuration)
    {
        _gatewayClient = gatewayClient;
        _emailLogoUrl = configuration["ScapiGateway:LogoUrl"] ?? string.Empty;
    }

    public async Task<bool> SendOtpEmailAsync(string recipientEmail, string customerName, string otpCode, string externalRefNumber)
    {
        var route = new ScapiMessageRoute
        {
            
            Interface = "SMS",
            RequestType = "EMAIL_OTP_BIMA",
            ExternalRefNumber = externalRefNumber
        };

        var body = new JsonObject
        {
            ["recipient_email"] = recipientEmail,
            ["subject"] = $"{customerName} OTP:{externalRefNumber}",
            ["customer_name"] = customerName,
            ["otp_text"] = otpCode,
            ["attachment"] = string.Empty,
            ["logo"] = _emailLogoUrl
        };

        var response = await _gatewayClient.InvokeAsync(route, body);
        return response?["error_code"]?.ToString() == "00";
    }

    public async Task<bool> SendOtpSmsAsync(string phoneNumber, string otpCode, string externalRefNumber)
    {
        var route = new ScapiMessageRoute
        {
            Interface = "SMS",
            RequestType = "SINGLE",
            ExternalRefNumber = externalRefNumber
        };

        var message = $"Your Insurance Platform OTP is {otpCode}. Do not share this code with anyone.";

        var body = new JsonObject
        {
            ["mobile_number"] = NormalizeKenyanPhoneNumber(phoneNumber),
            ["request_message"] = message,
            ["channel"] = "PORTAL",
            ["request_reference"] = externalRefNumber
        };

        var response = await _gatewayClient.InvokeAsync(route, body);
        return response?["error_code"]?.ToString() == "00";
    }

    
    private static string NormalizeKenyanPhoneNumber(string phoneNumber)
    {
        var digitsOnly = Regex.Replace(phoneNumber, @"\D", string.Empty);
        var lastNineDigits = digitsOnly.Length >= 9 ? digitsOnly[^9..] : digitsOnly;
        return "254" + lastNineDigits;
    }
}
