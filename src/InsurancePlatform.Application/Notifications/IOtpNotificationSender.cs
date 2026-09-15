namespace InsurancePlatform.Application.Notifications;


public interface IOtpNotificationSender
{
    
    Task<bool> SendOtpEmailAsync(string recipientEmail, string customerName, string otpCode, string externalRefNumber);

    Task<bool> SendOtpSmsAsync(string phoneNumber, string otpCode, string externalRefNumber);
}
