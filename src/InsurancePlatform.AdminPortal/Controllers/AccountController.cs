using System.Security.Claims;
using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.AdminPortal.Controllers;

/// <summary>
/// The two-step login handshake InsurancePlatform.Api requires (password
/// check -> OTP -> token), translated into ordinary MVC pages. Marked
/// [AllowAnonymous] at the class level on purpose - every action here
/// (including Logout) must be reachable by someone who ISN'T signed in yet.
/// </summary>
[AllowAnonymous]
public class AccountController : Controller
{
    private readonly IInsuranceApiClient _apiClient;

    public AccountController(IInsuranceApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;
        return View(new LoginViewModel());
    }

    /// <summary>Step 1 - checks the password, triggers an OTP. No token yet.</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var result = await _apiClient.LoginAsync(model.IdNo, model.Password);

        if (!result.Success)
        {
            model.ErrorMessage = result.Message;
            return View(model);
        }

        // Carries IdNo forward to the VerifyOtp step. TempData's default
        // provider is cookie-backed (CookieTempDataProvider), not
        // server-side session - matches this whole app's "no server-side
        // session" approach (see Program.cs).
        TempData["IdNo"] = model.IdNo;
        return RedirectToAction(nameof(VerifyOtp), new { returnUrl });
    }

    [HttpGet]
    public IActionResult VerifyOtp(string? returnUrl = null)
    {
        // Peek, not the indexer - a page refresh on this GET shouldn't
        // burn the one read TempData normally allows before it's gone.
        var idNo = TempData.Peek("IdNo") as string;

        if (string.IsNullOrEmpty(idNo))
        {
            // Landed here without completing step 1 (bookmarked/shared URL,
            // or TempData's cookie expired) - start over.
            return RedirectToAction(nameof(Login), new { returnUrl });
        }

        ViewData["ReturnUrl"] = returnUrl;
        return View(new VerifyOtpViewModel { IdNo = idNo });
    }

    /// <summary>Step 2 - verifies the OTP, receives a JWT, signs the browser in with a cookie carrying that JWT as a claim.</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> VerifyOtp(VerifyOtpViewModel model, string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var result = await _apiClient.VerifyOtpAsync(model.IdNo, model.OtpCode);

        if (!result.Success || result.Data is null)
        {
            model.ErrorMessage = result.Message;
            return View(model);
        }

        var token = result.Data.Token;

        // JwtTokenService builds the token from a plain List<Claim>, not a
        // ClaimsIdentity + SecurityTokenDescriptor - that path does NOT
        // shorten well-known claim types the way ASP.NET Core sometimes
        // does, so the JSON keys really are the long ClaimTypes URIs
        // (ClaimTypes.NameIdentifier / ClaimTypes.Role), not short names
        // like "sub"/"role". Reading them back with those same ClaimTypes
        // constants keeps this correct without hardcoding the URI strings
        // here.
        var tokenClaims = JwtClaimsReader.ReadClaims(token);
        var permissions = JwtClaimsReader.ReadPermissions(token);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, tokenClaims.GetValueOrDefault(ClaimTypes.NameIdentifier, string.Empty)),
            new Claim(ClaimTypes.Role, tokenClaims.GetValueOrDefault(ClaimTypes.Role, result.Data.RoleCode)),
            new Claim("full_name", tokenClaims.GetValueOrDefault("full_name", string.Empty)),
            new Claim(InsuranceApiClient.AccessTokenClaimType, token)
        };

        foreach (var permission in permissions)
        {
            if (!string.IsNullOrEmpty(permission))
            {
                claims.Add(new Claim("permission", permission));
            }
        }

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties
            {
                IsPersistent = false,
                ExpiresUtc = result.Data.ExpiresAtUtc
            });

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction("Index", "Home");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    [HttpGet]
    public IActionResult AccessDenied()
    {
        return View();
    }
}
