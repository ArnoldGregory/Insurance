using AmuraWebsite.Services;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddSingleton<IQuoteSubmissionService, QuoteSubmissionService>();

builder.Services.Configure<InsurancePlatformOptions>(
    builder.Configuration.GetSection(InsurancePlatformOptions.SectionName));
builder.Services.AddSingleton<PlatformTokenCache>();
builder.Services.AddHttpClient<IInsurancePlatformClient, InsurancePlatformClient>((sp, client) =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<InsurancePlatformOptions>>().Value;
    if (!string.IsNullOrWhiteSpace(options.BaseUrl))
    {
        client.BaseAddress = new Uri(options.BaseUrl);
    }
    client.Timeout = TimeSpan.FromSeconds(15);
});

// Motor purchase flow — separate client (pricing, client/vehicle
// registration, purchase, M-Pesa STK push), needs session state across
// its 3 steps since it's not a single-POST form like the other 5.
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
});
builder.Services.AddHttpClient<IMotorPurchaseClient, MotorPurchaseClient>((sp, client) =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<InsurancePlatformOptions>>().Value;
    if (!string.IsNullOrWhiteSpace(options.BaseUrl))
    {
        client.BaseAddress = new Uri(options.BaseUrl);
    }
    client.Timeout = TimeSpan.FromSeconds(20);
});
builder.Services.AddSingleton<MotorSessionStore>();

// Which API are we actually talking to? Every quote submitted through this
// site becomes a real row in that API's database, so the target is logged
// loudly at startup - a misconfigured BaseUrl otherwise stays invisible
// until someone notices test data in production.
var platformOptions = builder.Configuration
    .GetSection(InsurancePlatformOptions.SectionName)
    .Get<InsurancePlatformOptions>() ?? new InsurancePlatformOptions();

var apiBaseUrl = platformOptions.BaseUrl ?? string.Empty;
var apiUri = Uri.TryCreate(apiBaseUrl, UriKind.Absolute, out var parsed) ? parsed : null;
var isLiveApi = apiUri is not null
    && apiUri.Host.Contains("riziki.app", StringComparison.OrdinalIgnoreCase);

// Refuse to boot against the live API outside Production unless explicitly
// allowed. Local testing writes real quote rows, and Development/Testing
// should never do that by accident. Production keeps its normal behaviour so
// deployment is unaffected.
var allowLive = string.Equals(
    builder.Configuration["InsurancePlatform:AllowLiveApi"], "true", StringComparison.OrdinalIgnoreCase);

if (isLiveApi && !builder.Environment.IsProduction() && !allowLive)
{
    throw new InvalidOperationException(
        $"Refusing to start: BaseUrl '{apiBaseUrl}' points at the LIVE production API, " +
        "but the environment is not Production. Local runs write real quote data to the " +
        "live database. Set InsurancePlatform__BaseUrl to a local API (e.g. " +
        "http://localhost:5044), or set InsurancePlatform__AllowLiveApi=true if this is " +
        "intentional.");
}

var app = builder.Build();

var startupLog = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
startupLog.LogWarning(
    "AmuraWebsite starting in {Environment} against API {BaseUrl}{LiveNote}",
    app.Environment.EnvironmentName,
    string.IsNullOrWhiteSpace(apiBaseUrl) ? "(not configured)" : apiBaseUrl,
    isLiveApi ? "  *** THIS IS THE LIVE PRODUCTION API ***" : string.Empty);

// Startup dependency check: is the API actually reachable? Quote submission
// and the motor purchase flow all go through it, and without this check a
// missing API only shows up later as a failed form post with no explanation.
// The site deliberately stays up so the pages still render and this message
// is visible in the log.
if (!string.IsNullOrWhiteSpace(apiBaseUrl))
{
    try
    {
        using var probeClient = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
        var healthUrl = new Uri(new Uri(apiBaseUrl), "health");
        var healthResponse = await probeClient.GetAsync(healthUrl);
        if (healthResponse.IsSuccessStatusCode)
        {
            startupLog.LogInformation("API reachable at {BaseUrl}.", apiBaseUrl);
        }
        else
        {
            startupLog.LogWarning(
                "API at {BaseUrl} is running but reported {Status} for /health - its database is probably down.",
                apiBaseUrl, (int)healthResponse.StatusCode);
        }
    }
    catch (Exception ex)
    {
        startupLog.LogWarning(
            "Cannot reach the API at {BaseUrl}. Quote submission and purchases will fail until it is " +
            "running. Start InsurancePlatform.Api. Error: {Message}",
            apiBaseUrl, ex.Message);
    }
}

// Behind nginx (reverse proxy) in production — trust the X-Forwarded-*
// headers so HTTPS redirection, HSTS, and client IP all work correctly. 
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseSession();
app.UseAuthorization();

app.MapRazorPages();

app.Run();
