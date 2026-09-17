# SCAPI Email delivery failure — error_code 99 (EMAIL_OTP_BIMA)

Status: **OPEN — server-side (SCAPI), needs SCAPI/POA action. App-side mitigation now in
place (email→SMS OTP fallback, applied 2026-09-16).** This file documents the problem so
whoever owns the SCAPI box can act on it.

## Symptom

Login / registration OTP emails are never delivered. The API logs show the exact
failure, reproduced on every attempt (harvested from the API log, 2026-09-15):

```
INFO requestTypeBody : {"message_validation":{"api_user":"-","api_password":"-","token":"..."},
                        "message_route":{"interface":"SMS","request_type":"EMAIL_OTP_BIMA",
                        "external_ref_number":"20260915070939302"},
                        "message_body":{"recipient_email":"test.superadmin@example.com",
                        "subject":"Test SuperAdmin OTP:20260915070939302","customer_name":"Test SuperAdmin",
                        "otp_text":"111111","attachment":"",
                        "logo":"/root/scapi/bimadlineportaclient/wwwroot/assets/static/img/bimalogo.png"}}
INFO SCAPI ref=20260915070939302: invoking interface=SMS, request_type=EMAIL_OTP_BIMA.
INFO SCAPI ref=20260915070939302: response: {"error_code":"99","error_desc":"An unexpected error occurred. Please retry."}
```

## What we already ruled out (our side is fine)

- **Authentication:** the gateway *token* request succeeds every time
  (`"error_code":"00"` with a token) — the login part of the SCAPI contract is fine.
- **Payload shape:** SCAPI accepted the envelope and routed it; it did NOT reject the
  JSON (a schema/validation rejection comes back as a different, explicit code/desc).
- **Network:** the request reaches SCAPI; the `http 200` + JSON body are returned promptly (~0.6s).

So the error is thrown **inside SCAPI while processing the email** (generating the
template / handing off to its mailer).

## Most likely causes (check in this order, on the SCAPI server)

1. **Logo/template asset missing.** `message_body.logo` is
   `/root/scapi/bimadlineportaclient/wwwroot/assets/static/img/bimalogo.png` — a path on
   the SCAPI box. If that file was moved/renamed/absent, SCAPI's email renderer throws →
   `error_code 99`. Compare with the path used by a *working* email template on the same box.
2. **`EMAIL_OTP_BIMA` template not configured / renamed** in SCAPI's EmailBatch/template
   store (the same template id the old WorkMate/BimaDLine portal used).
3. **SMTP relay unreachable from the SCAPI box** (its mail server credential, sender
   address, or IP allowlist) — check SCAPI's own logs for a mail-send exception.
4. **`attachment` empty string** — our payload always sends `"attachment":""`. If the
   template pipeline calls the attachment loader unconditionally, an empty id could throw.
   (Change on our side, if SCAPI confirms this is the trigger: send `null`/omit the key.)

## Action needed (POA / SCAPI owner)

- Reproduce using the logged request body above and inspect the SCAPI-side stack trace /
  app logs for `EMAIL_OTP_BIMA`.
- Confirm the logo asset path resolves on the box (item 1) and the template id exists
  (item 2).
- Confirm SCAPI → SMTP connectivity for the sender address in play (item 3).

## In-app impact & current mitigation

- **Fallback (applied 2026-09-16):** `AuthService` (login + password reset) and
  `RegistrationService` now send the OTP **email-first, SMS-fallback** with the *same*
  code. When SCAPI returns `error_code 99` for the email, the code is automatically
  delivered to the account's phone via the SCAPI `SINGLE` (SMS) route instead — so
  login/registration/password-reset no longer hard-fail just because `EMAIL_OTP_BIMA` is
  down. OTP is still created exactly once (keyed by user+purpose), so the fallback can
  never mint a second, silently-issued code. A `LogWarn`/`LogInfo` line records which
  channel actually carried the code.
- If the account has **no email**, nothing changes: it goes straight to SMS.
- Only when **both** channels fail does the flow apply the old behaviour
  (`Notifications:AllowOtpDeliveryFailure` must stay **false** in production).
- Long-term it is wise to switch login OTPs to the **SMS** delivery path alone
  (`EMAIL_OTP_BIMA` → SCAPI `SINGLE`) — the app already supports it
  (`OtpNotificationSender.SendOtpSmsAsync`) — and keep email for receipts/quotes, or to
  get SCAPI's email pipeline fixed per the action list above.