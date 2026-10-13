using System.Text.Json.Nodes;
using InsurancePlatform.Application.Integrations;
using Microsoft.Extensions.Configuration;

namespace InsurancePlatform.Application.Payments;

/// <summary>
/// Composes the DARAJA_REGISTER_URLS message on top of the generic
/// IScapiGatewayClient - the C2B counterpart of MpesaStkPushService, same
/// shape and same gateway client. Reads Mpesa:BusinessShortCode straight
/// off IConfiguration, exactly like MpesaStkPushService does.
/// </summary>
public class MpesaC2BService : IMpesaC2BService
{
    private readonly IScapiGatewayClient _gatewayClient;
    private readonly string _businessShortCode;

    public MpesaC2BService(IScapiGatewayClient gatewayClient, IConfiguration configuration)
    {
        _gatewayClient = gatewayClient;
        _businessShortCode = configuration["Mpesa:BusinessShortCode"] ?? string.Empty;
    }

    public async Task<C2BRegisterResult> RegisterUrlsAsync(string responseType)
    {
        var route = new ScapiMessageRoute
        {
            Interface = "MPESA",
            RequestType = "DARAJA_REGISTER_URLS",
            ExternalRefNumber = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff")
        };

        // SCAPI's RMPESAMANAGER supplies both ConfirmationURL and
        // ValidationURL from the short code's own DB row - the request body
        // only carries which short code to register and the response type.
        var body = new JsonObject
        {
            ["business_short_code"] = _businessShortCode,
            ["response_type"] = string.IsNullOrWhiteSpace(responseType) ? "Completed" : responseType
        };

        var response = await _gatewayClient.InvokeAsync(route, body);

        if (response is null)
        {
            return new C2BRegisterResult
            {
                Success = false,
                Message = "Could not reach the payment gateway - please try again shortly."
            };
        }

        // error_code=="00" is SCAPI's gateway-level success; anything else is
        // a rejection or a RMPESAMANAGER-side exception. Same envelope
        // shapes as the STK path (JsonObject / JsonArray / plain value), so
        // pull the most useful text out of whichever one arrives.
        var errorCode = response["error_code"]?.ToString();
        var errorDesc = response["error_desc"];

        if (errorCode == "00")
        {
            return new C2BRegisterResult
            {
                Success = true,
                Message = "C2B Paybill URLs registered with M-Pesa."
            };
        }

        var description = errorDesc switch
        {
            JsonObject jo =>
                jo["error_desc"]?.ToString()
                ?? jo["ResponseDescription"]?.ToString()
                ?? jo["Message"]?.ToString(),
            JsonArray arr when arr[0] is JsonObject first => first["exception"]?.ToString(),
            JsonArray arr => $"Gateway error: {arr.ToJsonString()}",
            null => "Gateway rejected the request.",
            _ => errorDesc.ToString()
        };

        if (string.IsNullOrWhiteSpace(description))
        {
            description = "Gateway rejected the request.";
        }
        else if (description.Length > 300)
        {
            description = description[..300] + "...";
        }

        return new C2BRegisterResult { Success = false, Message = description };
    }
}
