# Amura Website — Phase 1

ASP.NET Core Razor Pages + Bootstrap 5 (CDN, no JS build step). Covers Tasks #1–#4
from the project plan; Task #5 (Content integration) is blocked on real copy/photos
from Amura.

## Run it

```
dotnet run
```

Requires the .NET 8 SDK. Opens on the URL printed in the console.

## What's built

- `Pages/Index.cshtml` — Home: hero, trust strip, product preview grid, about preview, CTA
- `Pages/About.cshtml` — story, values, real logo lockup
- `Pages/Services.cshtml` — all 5 products, each linking to its real Get Quote form
- `Pages/Quote/` — the 5 Get Quote forms (Task #3):
  - `MedicalIndividual` — individual/family medical
  - `MedicalCorporate` — group medical
  - `ProfessionalIndemnity` — short capture, then redirects to...
  - `Proposal` — the underwriting proposal form PI redirects into
  - `Travel` — travel insurance
  - `Domestic` — home/contents insurance
- `Pages/Contact.cshtml` — general contact form
- `Services/` — the submission pipeline (Task #4). Every form above (Contact + all
  5 quote forms) posts through `IQuoteSubmissionService`:
  - generates a reference number (e.g. `AMR-MED-260803-A1B2C`)
  - persists the submission to `App_Data/submissions.jsonl` (gitignored — has personal
    data in it)
  - logs the back-office routing and client acknowledgement email as clearly marked
    TODOs — both are real integration points, just waiting on Amura to pick a
    transactional email provider and confirm how they want submissions delivered.
    Swapping in the real providers only touches `Services/QuoteSubmissionService.cs`,
    nothing in the form pages.
- `wwwroot/images/` — favicon set + logo assets (see below)
- `wwwroot/css/site.css` — brand tokens: gold gradient #D4AF37 → #C5A028, ink/charcoal
  darks, Fraunces (display) + Inter (body)

## Logo

Real logo is in. Favicon set, nav/footer icon, and the About page lockup are all
wired up in `wwwroot/images/`. If you regenerate assets from a newer source file,
keep the filenames the same and they'll drop straight in.

## Marked as PENDING in the code

Search for `PENDING` comments across `.cshtml` and `.cs` files. Three different things
get flagged this way:

1. **Real copy/photography** from Amura (Task #5 — not started, blocked on Amura).
2. **Get Quote field lists** — every quote form's field set is a reasonable placeholder,
   not yet confirmed against Amura's actual per-product spec. The plan calls out
   Domestic specifically (a separate field-list spreadsheet) — check that's been
   received before treating that form's fields as final.
3. **Integration provider choices** — email sending and back-office routing are
   functionally wired but log instead of actually sending/routing, pending Amura's
   choice of transactional email provider and DMVIC/insurer access (see the plan's
   Integrations & APIs sheet).

## Next per the plan

- Task #5 — Content integration (blocked on Amura: written copy, remaining photos)
- Then Internal QA, client review, and deploy to close out Phase 1
- Confirm quote field lists against Amura's actual spec before Task #5 content pass
