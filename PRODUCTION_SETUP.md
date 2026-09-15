# PRODUCTION SETUP (InsurancePlatform.Api)

How to deploy the API so no secret lives in committed files. The repo's
`appsettings.json` contains only `CHANGE_ME` placeholders; real values are
applied at deploy time. ASP.NET Core's configuration layering automatically
lets environment variables (or `dotnet user-secrets`) override them -- no
code change needed.

## Environment variables (equivalent to user-secrets on the target box)

| Variable | Value |
|---|---|
| `ConnectionStrings__DefaultConnection` | full MySQL connection string (server, user, password, db) with `CharacterSet=utf8mb4;` |
| `Jwt__Key` | a long random key (>= 32 chars). **Change it from the dev value.** |
| `Jwt__Issuer` | `InsurancePlatform.Api` |
| `Jwt__Audience` | `InsurancePlatform.Clients` |
| `Jwt__ExpiryMinutes` | session length in minutes |
| `ScapiGateway__Url` | SCAPI submit URL |
| `ScapiGateway__ApiUser` | SCAPI API user (base64) |
| `ScapiGateway__ApiPassword` | SCAPI API password (base64) |
| `GovConnect__Url` | `https://api.kra.go.ke` |
| `GovConnect__ConsumerKey` | real KRA consumer key |
| `GovConnect__SecretKey` | real KRA secret key |
| `Mpesa__BusinessShortCode` | e.g. `4029873` |
| `Mpesa__CallbackUrl` | publicly reachable callback, must be exactly the one registered with Daraja, e.g. `https://insuranceapi.riziki.app/api/mpesa/callback/stk` |
| `Notifications__AllowOtpDeliveryFailure` | **`false` in production** (see below) |
| `QuoteOffersStorage__Root` | writable folder for uploaded offer documents |

Syntax detail: dunder (`__`) between segments maps to `Section:Key`.

Equivalent for local machines using the dotnet CLI (secrets stored in the
user profile, never committed):

```
dotnet user-secrets init  # once
dotnet user-secrets set "Jwt:Key" "<secret>"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<connection string>"
```

## OTP handling

- `Notifications:DevOtp` is a **dev-only** fixed OTP. It only takes effect
  when `Notifications:AllowOtpDeliveryFailure` is `true`, and it lives in
  the gitignored `appsettings.Development.json`. Do NOT configure either
  setting in a production environment -- with them absent the API generates
  real random OTPs (RandomNumberGenerator) and requires the SCAPI gateway
  delivery to succeed before the code is issued.

## Database tidy-up before go-live

- Azure/prod DB collation: run `prod_collation_normalization.sql`
  (requires MySQL 8+; needs a maintenance window, converts every table to
  `utf8mb4_0900_ai_ci`).
- Remove the DEV staff logins: run `prod_seed_account_purge.sql`
  (disables `90000001`..`90000004`; see the optional hard-delete block
  inside).

## Swagger

The OpenAPI/Swagger UI is intentionally left enabled in all environments
(the operator previously asked for it in production and test). If it ever
needs locking down, gate the two `UseSwagger(...)` calls in `Program.cs`
behind `app.Environment.IsDevelopment()` or a role check.