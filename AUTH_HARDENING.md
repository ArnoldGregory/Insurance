# AUTH HARDENING — audit results & changes

Status: audit complete; the two code-level gaps found are fixed in this
commit. Recorded here so the reasoning and the remaining (deployment-level)
recommendations survive.

## What is already solid (verified in code)

- **Passwords:** BCrypt (`Infrastructure` `BCryptPasswordHasher`), no plaintext
  storage; `failed_login_attempts` + `locked_until` on `Users` for lockout.
- **OTP**: 6 digits, hashed with SHA-256 before storage, 5-minute expiry, and
  the verify proc locks after 5 wrong attempts. No hardcoded OTP survives in
  code anymore (dev-only `Notifications:DevOtp` lives in gitignored config and
  is inert unless `AllowOtpDeliveryFailure=true`).
- **JWT**: HS256; issuer, audience, signing key and lifetime all validated;
  expiry always set; 1-minute clock skew; `RequireExpirationTime = true`.
  Tokens carry role/permission/channel claims and are bound to `X-Channel` by
  `ChannelBindingMiddleware`.
- **Channel-service tokens**: API keys stored hashed (SHA-256), matched
  case-insensitively.

## Changes made in this commit (Program.cs)

1. **Minimum JWT signing-key length guard (256 bits).** Startup now throws if
   `Jwt:Key` is under 32 UTF-8 bytes. Prevents a short/weak key silently
   producing forgeable tokens. Dev key length is fine; production should set a
   strong random key (see `PRODUCTION_SETUP.md`).
2. **Algorithm pinning.** `ValidAlgorithms = [SecurityAlgorithms.HmacSha256]`
   on `TokenValidationParameters`, blocking algorithm-confusion / `alg:none`
   downgrades.

## Applied elsewhere earlier

- Hardcoded OTP removed from `AuthService` / `RegistrationService`
  (config-driven dev OTP + `RandomNumberGenerator` codes in prod).
- JWT/DB secrets removed from committed `appsettings.json` (env override /
  user-secrets documented in `PRODUCTION_SETUP.md`).

## Remaining recommendations (deployment/ops, not code)

- Authenticate rate limits: put login / verify-otp routes behind a reverse
  proxy rate limiter (e.g. nginx `limit_req`) or ASP.NET rate limiting, since
  lockout is per-account, not per-IP.
- Rotate `Jwt:Key` (and channel-service API keys) on a schedule; the seed keys
  in `Insurance_API_Schema.sql` must be replaced before prod go-live.
- Consider shortening `Jwt:ExpiryMinutes` for staff vs. client tokens once
  session behavior is agreed.
- Channel-service API keys are single unsalted SHA-256 hashes; acceptable for
  high-entropy out-of-band credentials, but if one ever leaks, rotate it and
  the seed rows immediately.