using System.Reflection;
using System.Text;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Api.Middleware;
using InsurancePlatform.Application.Auth;
using InsurancePlatform.Application.Clients;
using InsurancePlatform.Application.Integrations;
using InsurancePlatform.Application.Notifications;
using InsurancePlatform.Application.Payments;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Data.Common;
using InsurancePlatform.Data.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Infrastructure.Auth;
using InsurancePlatform.Infrastructure.Integrations.GovConnect;
using InsurancePlatform.Infrastructure.Integrations.Scapi;
using InsurancePlatform.Infrastructure.Logging;
using InsurancePlatform.Infrastructure.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using NLog;
using NLog.Web;


var nlogLogger = LogManager.Setup().LoadConfigurationFromFile("NLog.config").GetCurrentClassLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Logging.ClearProviders();
    builder.Host.UseNLog();

    // Add services to the container.

    // Purely cosmetic/URL-style - routing is already case-insensitive, so
    // this doesn't change what matches what. Just makes every generated
    // route (and what Swagger displays) lowercase: /api/clients/{id}
    // instead of /api/Clients/{id}, which is what [controller]/[action]
    // tokens would otherwise render as (they substitute the literal C#
    // class/method name, capitalization and all).
    builder.Services.Configure<RouteOptions>(options =>
    {
        options.LowercaseUrls = true;
        options.LowercaseQueryStrings = false;
    });

    builder.Services.AddControllers();

    // Swashbuckle: generates the OpenAPI document (the JSON description of
    // every endpoint) AND serves the interactive Swagger UI page that reads
    // it. SwaggerDoc just names/describes the one API version we have.
    builder.Services.AddSwaggerGen(options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Title = "Insurance Platform API",
            Version = "v1",
            Description = "Role-based Insurance API - Motor, Medical, Travel, Professional " +
                           "Indemnity and Domestic products, quotes, purchases, payments and " +
                           "agent commissions."
        });

        // Pulls in every /// <summary>, <param>, <response> XML comment from
        // this project (enabled by GenerateDocumentationFile in the .csproj)
        // so Swagger UI shows real descriptions, not just bare type names.
        var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
        {
            options.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
        }

        // Our .csproj files all have <Nullable>enable</Nullable>, so a
        // property typed `string Name` (non-nullable) versus `string? Notes`
        // (nullable) is a real, compiler-enforced distinction already.
        // SupportNonNullableReferenceTypes only sets the schema's "nullable"
        // flag (can this field's value be null); it does NOT put the field
        // in the schema's "required" list on its own - those are two
        // separate Swashbuckle opt-ins even though they sound like the same
        // thing. NonNullableReferenceTypesAsRequired is the one that
        // actually adds non-nullable properties to "required", which is
        // what makes Swagger UI draw the red asterisk. Both are needed;
        // neither implies the other.
        options.SupportNonNullableReferenceTypes();
        options.NonNullableReferenceTypesAsRequired();

        // Registers "Bearer" as a known security scheme purely for Swagger
        // UI's benefit - this is what makes the Authorize button appear at
        // all, and what puts a padlock icon next to /api/Auth/me (and every
        // future [Authorize] endpoint). It does NOT affect real
        // authentication in any way - that's entirely the
        // AddAuthentication().AddJwtBearer(...) block further down, which
        // runs whether or not Swagger even exists. This block only teaches
        // the DOCUMENTATION UI how to attach the header for you.
        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Description = "Paste just the raw token - Swagger adds the \"Bearer \" prefix for you. Get one from /api/Auth/login + /api/Auth/verify-otp, or /api/Auth/register + /api/Auth/verify-registration-otp.",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT"
        });

        // Tells Swagger UI to attach the "Bearer" scheme above to EVERY
        // endpoint by default, once you've clicked Authorize and pasted a
        // token in. Endpoints marked [AllowAnonymous] still work fine
        // without one - this only controls what Swagger UI sends, real
        // authorization still happens (or doesn't need to) server-side.
        //
        // Microsoft.OpenApi 2.x breaking change (this bit us): AddSecurityRequirement
        // no longer takes a plain OpenApiSecurityRequirement object - it takes a
        // Func<OpenApiDocument, OpenApiSecurityRequirement> delegate, and there's no
        // more OpenApiSecurityScheme.Reference / OpenApiReference pair to point back
        // at the "Bearer" definition above. Instead you construct an
        // OpenApiSecuritySchemeReference("Bearer", document) - the scheme's id plus
        // the in-progress document Swashbuckle hands you - and use THAT as the
        // dictionary key, with an empty scope list as the value (no OAuth2 scopes
        // apply to a plain bearer token).
        options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference("Bearer", document)] = []
        });
    });

    // Scoped = one instance per HTTP request. CorrelationContext holds this
    // request's ref; LoggerManager is the concrete ILoggerManager everything
    // else in the app (services, repositories) will ask for by interface.
    builder.Services.AddScoped<CorrelationContext>();
    builder.Services.AddScoped<ILoggerManager, LoggerManager>();

    // The Data layer's plumbing: one executor per request, talking to MySQL
    // via the connection string read from appsettings.json.
    builder.Services.AddScoped<IStoredProcedureExecutor, MySqlStoredProcedureExecutor>();

    // First real repository. Every future one (IClientRepository, etc.) gets
    // registered the same way: interface from Application, implementation
    // from Data.
    builder.Services.AddScoped<IProductRepository, ProductRepository>();

    // Catalog/Pricing module - Underwriters CRUD plus TPO/Comprehensive
    // Motor pricing. IProductRepository above already covers the read-only
    // Products/MotorCategories/MotorVehicleClasses/Periods lookups.
    builder.Services.AddScoped<IUnderwriterRepository, UnderwriterRepository>();
    builder.Services.AddScoped<IUnderwriterPolicyLevelNumberRepository, UnderwriterPolicyLevelNumberRepository>();
    builder.Services.AddScoped<IPricingRepository, PricingRepository>();

    // Admin Portal navigation - independent of the Catalog/Pricing module
    // above, but registered nearby since it's the same "reference-data-ish,
    // admin-managed" shape.
    builder.Services.AddScoped<IMenuRepository, MenuRepository>();

    // Binds the "ScapiGateway" section of appsettings.json into ScapiSettings,
    // so ScapiGatewayClient can ask for IOptions<ScapiSettings> instead of
    // reading IConfiguration directly.
    builder.Services.Configure<ScapiSettings>(builder.Configuration.GetSection("ScapiGateway"));

    // AddHttpClient (not AddScoped/new HttpClient()) - this is ASP.NET Core's
    // typed-client pattern. It hands ScapiGatewayClient an HttpClient drawn
    // from a pool the framework manages, which avoids a well-known problem
    // where creating many short-lived HttpClient instances by hand can
    // exhaust available network sockets under load. This is the *generic*
    // gateway client - it knows nothing about OTP specifically.
    builder.Services.AddHttpClient<IScapiGatewayClient, ScapiGatewayClient>();

    // GovConnect (KRA PIN checker) - same typed-client pattern as SCAPI
    // above, but a completely separate gateway/vendor/auth shape. Used by
    // ClientLookupService to prefill name+KRA PIN for someone who isn't
    // already in our own database.
    builder.Services.Configure<GovConnectSettings>(builder.Configuration.GetSection("GovConnect"));
    builder.Services.AddHttpClient<ITaxpayerLookupClient, GovConnectClient>();

    // OtpNotificationSender (Application) composes OTP-specific message
    // bodies on top of the generic IScapiGatewayClient above - this is the
    // one AuthService will actually depend on.
    builder.Services.AddScoped<IOtpNotificationSender, OtpNotificationSender>();

    // QuoteNotificationSender (Application) - same pattern as OtpNotificationSender
    // above, three PLACEHOLDER email templates (see IQuoteNotificationSender's
    // own doc comment) for the quote-request-received/staff-notify/offers-
    // comparison emails. QuoteRequestsController depends on this.
    builder.Services.AddScoped<IQuoteNotificationSender, QuoteNotificationSender>();

    // MpesaStkPushService (Application) composes DARAJA_STK message bodies
    // on the same generic IScapiGatewayClient - same pattern as
    // OtpNotificationSender above, different message shape. PaymentsController
    // depends on this for POST /api/payments/stk-push.
    builder.Services.AddScoped<IMpesaStkPushService, MpesaStkPushService>();

    // Authentication module wiring - every interface here follows the same
    // pattern as everything above: Application/Domain define the contract,
    // Data or Infrastructure supply the concrete class.
    builder.Services.AddScoped<IUserRepository, UserRepository>();
    builder.Services.AddScoped<IOtpRepository, OtpRepository>();
    builder.Services.AddScoped<IRoleRepository, RoleRepository>();
    builder.Services.AddScoped<IChannelServiceRepository, ChannelServiceRepository>();
    builder.Services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
    builder.Services.AddScoped<ITokenService, JwtTokenService>();
    builder.Services.AddScoped<IAuthService, AuthService>();

    // Self-registration - IClientRepository is the first Client repository
    // in the codebase (more methods will join it as Clients/Vehicles gets
    // built out); RegistrationService mirrors AuthService's shape closely.
    builder.Services.AddScoped<IClientRepository, ClientRepository>();
    builder.Services.AddScoped<IRegistrationService, RegistrationService>();

    // Client/Vehicle CRUD - IClientRepository already registered above.
    builder.Services.AddScoped<IVehicleRepository, VehicleRepository>();
    builder.Services.AddScoped<IClientLookupService, ClientLookupService>();

    // Quotes module - the non-Motor quote request/offer workflow.
    builder.Services.AddScoped<IQuoteRequestRepository, QuoteRequestRepository>();
    builder.Services.AddScoped<IQuoteOfferRepository, QuoteOfferRepository>();

    // Where uploaded underwriter-quote documents (QuoteOffers.document_path)
    // actually get saved - see IQuoteOfferDocumentStorage's doc comment for
    // why local disk was chosen. AddScoped is overkill for something with no
    // per-request state, but matches this file's existing convention of
    // scoping everything to the request rather than mixing lifetimes.
    builder.Services.AddScoped<InsurancePlatform.Api.Services.IQuoteOfferDocumentStorage, InsurancePlatform.Api.Services.LocalQuoteOfferDocumentStorage>();

    // Purchases/Payments - usp_Purchase_Create is the central proc tying
    // Motor pricing, Quotes and Commissions together in one transaction.
    builder.Services.AddScoped<IPurchaseRepository, PurchaseRepository>();
    builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();

    // Commissions - rates/overrides (what % an agent earns) and the
    // earnings ledger/withdrawal flow (an agent's actual money).
    builder.Services.AddScoped<IAgentCommissionRateRepository, AgentCommissionRateRepository>();
    builder.Services.AddScoped<IAgentCommissionRepository, AgentCommissionRepository>();

    // JWT bearer authentication - this is the side that VALIDATES an
    // incoming "Authorization: Bearer <token>" header on every request,
    // as opposed to Infrastructure's JwtTokenService, which only ISSUES
    // tokens at login time. Both read the same "Jwt" appsettings.json
    // section, so a token JwtTokenService signs is one this validation
    // will accept.
    var jwtKey = builder.Configuration["Jwt:Key"]
        ?? throw new InvalidOperationException("Jwt:Key is not configured in appsettings.json.");
    var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? string.Empty;
    var jwtAudience = builder.Configuration["Jwt:Audience"] ?? string.Empty;

    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = jwtIssuer,
                ValidateAudience = true,
                ValidAudience = jwtAudience,
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                ValidateLifetime = true,
                // A small allowance for clock drift between this server and
                // whichever machine issued the token - without this, a token
                // that's technically still valid can get rejected as
                // "expired" if the two clocks are even a few seconds apart.
                ClockSkew = TimeSpan.FromMinutes(1)
            };
        });

    // One named policy per PermissionCodes constant. [Authorize(Policy =
    // PermissionCodes.CreateClient)] on a future endpoint means "the
    // caller's JWT must contain a 'permission' claim with exactly this
    // value". RequireClaim checks for ANY claim of that type/value among
    // however many the token carries - which matches JwtTokenService
    // exactly, since it adds one "permission" claim per code the caller's
    // role has (read from usp_Role_GetPermissions at login/registration
    // time). Written out one line per code on purpose, not via reflection
    // over PermissionCodes' fields - slightly more typing, but it's obvious
    // at a glance exactly which policies exist and what each one checks.
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

    // Swagger UI deliberately runs in every environment, not just
    // Development - you asked for it available in both production and test.
    // Trade-off worth knowing: this means anyone who can reach the API can
    // see its full endpoint documentation. That's a reasonable choice for an
    // internal/partner API; if this ever needs to be locked down, the usual
    // fix is putting these two lines back behind an environment or role
    // check rather than removing them.
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "Insurance Platform API v1");
    });

    // Genuinely first in the pipeline - it needs to wrap everything else,
    // including CorrelationMiddleware and authentication/authorization, so
    // an exception thrown anywhere still comes back as an ApiResponse<T>
    // instead of ASP.NET Core's bare default error page.
    app.UseMiddleware<ExceptionHandlingMiddleware>();

    // Every request gets a ref right after that, before anything else runs,
    // including requests that go on to fail authentication or hit an
    // unmapped route. See CorrelationMiddleware's doc comment.
    app.UseMiddleware<CorrelationMiddleware>();

    app.UseHttpsRedirection();

    // Serves whatever's under wwwroot. Underwriter-quote documents no longer
    // live here - they're written to the shared folder configured at
    // QuoteOffersStorage:Root (outside webroot) and streamed back through the
    // authenticated GET .../offers/{offerId}/document endpoint instead, so
    // there's no unauthenticated static-file exposure for them anymore.
    app.UseStaticFiles();

    // Authentication before authorization, always - authorization needs to
    // know WHO the caller is (which authentication establishes by validating
    // the JWT and populating HttpContext.User) before it can decide WHAT
    // they're allowed to do.
    app.UseAuthentication();

    // Between Authentication and Authorization on purpose - needs
    // HttpContext.User already populated (Authentication does that) but
    // should reject a channel mismatch BEFORE spending time evaluating
    // [Authorize]/policy checks that follow.
    app.UseMiddleware<ChannelBindingMiddleware>();

    app.UseAuthorization();

    app.MapControllers();

    app.Run();
}
catch (Exception ex)
{
    nlogLogger.Error(ex, "Program stopped because of an exception during startup.");
    throw;
}
finally
{
    LogManager.Shutdown();
}
