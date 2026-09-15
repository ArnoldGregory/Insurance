using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

public class LoginViewModel
{
    [Required(ErrorMessage = "ID number is required.")]
    [Display(Name = "ID Number")]
    public string IdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [DataType(DataType.Password)]
    public string Password { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }
}

/// <summary>
/// Step 2 of login. IdNo is carried forward as a hidden field rather than
/// server-side session state - this whole app avoids server-side session
/// entirely (see Program.cs's cookie-auth comment), so the two-step
/// login/OTP handshake has to carry its one piece of state (which ID
/// number this OTP belongs to) through the form itself instead.
/// </summary>
public class VerifyOtpViewModel
{
    [Required]
    public string IdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Enter the OTP code sent to you.")]
    [Display(Name = "OTP Code")]
    public string OtpCode { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }
}
