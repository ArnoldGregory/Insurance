# Insurance Platform (ex-WorkMate, BimaDLine)

.NET 10 / ASP.NET Core solution for an auto-insurance platform.

## Repo layout (all under `/src`)

| Project | Purpose |
|---|---|
| `InsurancePlatform.Api` | REST API (`http://localhost:5044`, `https://localhost:7125`). Auth (password + OTP → JWT), quotes, pricing, purchases, payments, menus. DB access is stored-procedure only (MySQL via MySqlConnector). |
| `InsurancePlatform.AdminPortal` | Razor Pages/MVC admin portal (`http://localhost:5150`). Handles the two-step login (password → OTP → JWT cookie), sidebar menu from `GET /api/menus/mine`. |
| `InsurancePlatform.Application` | Use-cases / command & query services. |
| `InsurancePlatform.Domain` | Entities and domain rules. |
| `InsurancePlatform.Infrastructure` | Data contracts, `JwtTokenService`, email/SMS gateway (SCAPI), payment gateway (M-Pesa) clients. |
| `InsurancePlatform.Data` | Repository implementations + stored-proc invocation. |
| `InsurancePlatform.Web_Admin_Blazor` | (if present) Blazor admin UI. |

Root SQL files hold the schema (`Insurance_API_Schema.sql`) and the stored procedures
(`Insurance_API_StoredProcs_*.sql`), plus migrations for menus, pricing, benefits, etc.

## Auth flow

1. `POST /api/auth/login` — checks id_no + password, issues an OTP (SCAPI email/SMS).
2. `POST /api/auth/verify-otp` — verifies the code, returns a JWT (claims: user id,
   role_code, permissions, `channel`).
3. `ChannelBindingMiddleware` binds a token to the `X-Channel` it was issued for
   (`PORTAL`, `MOBILE`, channel-service USSD/WhatsApp).

Development escape hatch: `Notifications:AllowOtpDeliveryFailure=true` lets logins
proceed even if the SCAPI email delivery fails (OTP is still stored and verifiable).
In production this must stay `false`.

## Configuration & secrets

Real credentials (DB password, `Jwt:Key`, SCAPI / GovConnect keys) live in
`appsettings.Development.json`, which is **gitignored**. The committed
`appsettings.json` contains only placeholders. Set real values via environment
variables / user-secrets in any non-local environment.

## DB notes

- Local MySQL is normalized to `utf8mb4_0900_ai_ci` (all tables + DB), with
  `CharacterSet=utf8mb4;` in the connection string (MySQL 8 session default).
- All data access goes through stored procedures named `usp_*`.

## Postman

`Insurance Platform API.postman_collection.json` / `Insurance_API.postman_collection.json`
at the repo root cover auth, quotes, and payments flows.