using InsurancePlatform.AdminPortal.Models;
using InsurancePlatform.AdminPortal.Services;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

// Standard Razor MVC (controllers + views) - this app renders HTML server-side,
// it does not serve a JSON API of its own.
builder.Services.AddControllersWithViews();

// IHttpContextAccessor lets InsuranceApiClient (a scoped service) read the
// CURRENT request's signed-in user - specifically, the JWT we stashed in a
// claim at login (see AccountController.VerifyOtp) - without every
// controller having to fish it out of HttpContext.User itself and pass it
// down manually on every call.
builder.Services.AddHttpContextAccessor();

// Short-lived, in-process cache for GET /api/menus/mine's result (see
// InsuranceApiClient.GetMyMenuAsync) so the sidebar isn't refetched from
// the API on every single page render. Not a distributed cache - fine for
// a single-instance deployment; revisit if this ever runs behind a load
// balancer with more than one Admin Portal instance.
builder.Services.AddMemoryCache();

// Server-side session for storing large wizard drafts (e.g. comprehensive
// comparison data) without hitting cookie size limits.
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(60);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// The one HttpClient this whole app uses to talk to InsurancePlatform.Api.
// BaseAddress comes from appsettings.json's InsuranceApi:BaseUrl (e.g.
// http://localhost:5044 in Development - see InsurancePlatform.Api's own
// launchSettings.json for that port). AddHttpClient<TInterface, TImpl> is
// the same typed-client pattern InsurancePlatform.Api itself uses for
// ScapiGatewayClient/GovConnectClient - avoids the socket-exhaustion
// problem of `new HttpClient()` per call, and gives InsuranceApiClient a
// pre-configured client without it having to read IConfiguration itself.
var apiBaseUrl = builder.Configuration["InsuranceApi:BaseUrl"]
    ?? throw new InvalidOperationException("InsuranceApi:BaseUrl is not configured in appsettings.json.");

builder.Services.AddHttpClient<IInsuranceApiClient, InsuranceApiClient>(client =>
{
    client.BaseAddress = new Uri(apiBaseUrl);
});

// Cookie authentication - NOT JWT bearer. This app is a browser-facing MVC
// site, not an API: once a user completes the login+OTP handshake against
// InsurancePlatform.Api and we get back a JWT, we sign the BROWSER in with
// an encrypted auth cookie (SignInAsync in AccountController.VerifyOtp),
// carrying the user_id/role_code/full_name as ordinary claims plus the raw
// JWT itself as one more claim ("access_token"). Every later request to
// this portal is authenticated by that cookie, the same as any normal
// ASP.NET Core MVC site with forms auth - InsuranceApiClient is the one
// piece that reads the "access_token" claim back out and attaches it as
// "Authorization: Bearer ..." (plus "X-Channel: PORTAL") when it calls the
// real API on the signed-in user's behalf.
builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.LogoutPath = "/Account/Logout";
        // Matches InsurancePlatform.Api's Jwt:ExpiryMinutes default (60) -
        // the portal's own session shouldn't outlive the token it's
        // carrying, since InsuranceApiClient would just start getting 401s
        // from the real API once the underlying JWT expires anyway.
        options.ExpireTimeSpan = TimeSpan.FromMinutes(60);
        options.SlidingExpiration = false;
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(PermissionCodes.CreateAdmin, p => p.RequireClaim("permission", PermissionCodes.CreateAdmin));
    options.AddPolicy(PermissionCodes.CreateAgent, p => p.RequireClaim("permission", PermissionCodes.CreateAgent));
    options.AddPolicy(PermissionCodes.CreateClient, p => p.RequireClaim("permission", PermissionCodes.CreateClient));
    options.AddPolicy(PermissionCodes.EditClient, p => p.RequireClaim("permission", PermissionCodes.EditClient));
    options.AddPolicy(PermissionCodes.ManageUnderwriter, p => p.RequireClaim("permission", PermissionCodes.ManageUnderwriter));
    options.AddPolicy(PermissionCodes.ManagePricing, p => p.RequireClaim("permission", PermissionCodes.ManagePricing));
    options.AddPolicy(PermissionCodes.PurchaseOnBehalf, p => p.RequireClaim("permission", PermissionCodes.PurchaseOnBehalf));
    options.AddPolicy(PermissionCodes.ViewAllPurchases, p => p.RequireClaim("permission", PermissionCodes.ViewAllPurchases));
    options.AddPolicy(PermissionCodes.DownloadReports, p => p.RequireClaim("permission", PermissionCodes.DownloadReports));
    options.AddPolicy(PermissionCodes.WithdrawCommission, p => p.RequireClaim("permission", PermissionCodes.WithdrawCommission));
    options.AddPolicy(PermissionCodes.ManageChannels, p => p.RequireClaim("permission", PermissionCodes.ManageChannels));
    options.AddPolicy(PermissionCodes.ManageMenus, p => p.RequireClaim("permission", PermissionCodes.ManageMenus));
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// Authentication before Authorization, same ordering reasoning as
// InsurancePlatform.Api's own Program.cs - Authorization needs to know WHO
// the caller is (from the cookie) before it can decide what they're
// allowed to see.
app.UseAuthentication();
app.UseAuthorization();
app.UseSession();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
