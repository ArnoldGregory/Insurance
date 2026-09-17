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

var app = builder.Build();

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
