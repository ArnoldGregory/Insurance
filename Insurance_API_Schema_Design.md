# Insurance Platform — Schema Design (v1)
**Stack:** C# / .NET, ADO.NET, MySQL, pure stored procedures
**Channels:** Web Portal, Website (guest + self-service), Mobile API, USSD, WhatsApp

Legend: **PK** primary key · **FK** foreign key · **NN** not null · **U** unique

---

## 1. Roles, Users, Clients (Auth & RBAC)

### Roles
| Column | Type | Notes |
|---|---|---|
| role_id | BIGINT UNSIGNED, PK | |
| role_code | VARCHAR(20), NN, U | short code for use in application constants/policies — see mapping below |
| name | VARCHAR(50), NN, U | SUPER_ADMIN, AGENT_ADMIN, AGENT, SUPPORT_AGENT, CLIENT, CHANNEL_SERVICE |
| description | VARCHAR(255) | |
| is_active | TINYINT(1), NN, default 1 | |

**role_code mapping:**
| name | role_code |
|---|---|
| SUPER_ADMIN | SA |
| AGENT_ADMIN | AA |
| AGENT | AG |
| SUPPORT_AGENT | SP |
| CLIENT | CL |
| CHANNEL_SERVICE | CS |

### Permissions
| Column | Type | Notes |
|---|---|---|
| permission_id | BIGINT UNSIGNED, PK | |
| code | VARCHAR(100), NN, U | e.g. CREATE_ADMIN, CREATE_AGENT, CREATE_CLIENT, EDIT_CLIENT, MANAGE_UNDERWRITER, MANAGE_PRICING, PURCHASE_ON_BEHALF, VIEW_ALL_PURCHASES, DOWNLOAD_REPORTS, WITHDRAW_COMMISSION |
| description | VARCHAR(255) | |

### RolePermissions
| Column | Type | Notes |
|---|---|---|
| role_id | BIGINT UNSIGNED, PK, FK → Roles | |
| permission_id | BIGINT UNSIGNED, PK, FK → Permissions | |

**Seed matrix (from requirements gathered):**
- SUPER_ADMIN: CREATE_ADMIN, overall system support — **not** CREATE_CLIENT / CREATE_AGENT / PURCHASE_ON_BEHALF
- AGENT_ADMIN: CREATE_AGENT, CREATE_CLIENT, EDIT_CLIENT, PURCHASE_ON_BEHALF, MANAGE_UNDERWRITER, MANAGE_PRICING, DOWNLOAD_REPORTS
- AGENT: CREATE_CLIENT (own), EDIT_CLIENT (own), PURCHASE_ON_BEHALF, WITHDRAW_COMMISSION
- SUPPORT_AGENT: CREATE_CLIENT, EDIT_CLIENT, PURCHASE_ON_BEHALF, VIEW_ALL_PURCHASES — **not** MANAGE_PRICING / CREATE_AGENT / DOWNLOAD_REPORTS
- CLIENT: view own records only
- CHANNEL_SERVICE: scoped to quote/purchase/lookup-by-id only (used by USSD/WhatsApp/Website guest flows)

### Users
*Anyone who can log in — staff and clients who have activated login.*
| Column | Type | Notes |
|---|---|---|
| user_id | BIGINT UNSIGNED, PK | |
| role_id | BIGINT UNSIGNED, NN, FK → Roles | |
| id_no | VARCHAR(50), NN, U | national ID — login identifier |
| full_name | VARCHAR(150), NN | |
| email | VARCHAR(150) | |
| phone | VARCHAR(20), NN | |
| password_hash | VARCHAR(255), NN | |
| status | VARCHAR(20), NN | ACTIVE / INACTIVE / LOCKED |
| must_change_password | TINYINT(1), NN, default 0 | |
| created_by | BIGINT UNSIGNED, FK → Users | null = self-registered |
| created_on | DATETIME, NN | |
| last_login_on | DATETIME | |
| isdeleted | TINYINT(1), NN, default 0 | |

### Clients
*Every person who has ever bought insurance — the insured party, independent of login access.*
| Column | Type | Notes |
|---|---|---|
| client_id | BIGINT UNSIGNED, PK | |
| id_no | VARCHAR(50), NN, U | lookup/dedup key |
| full_name | VARCHAR(150), NN | |
| dob | DATE | |
| email | VARCHAR(150) | |
| phone | VARCHAR(20), NN | |
| address | VARCHAR(255) | |
| kra_pin | VARCHAR(20) | |
| user_id | BIGINT UNSIGNED, FK → Users, nullable, U | set only once login is granted/activated — unique so one login can never map to more than one Client record |
| registered_by_user_id | BIGINT UNSIGNED, FK → Users, nullable | agent/support/admin who onboarded them; null if self-service. Permanent — never overwritten. |
| registration_channel | VARCHAR(20), NN | PORTAL / USSD / WHATSAPP / WEBSITE |
| created_on | DATETIME, NN | |
| isdeleted | TINYINT(1), NN, default 0 | |

### OtpVerifications
| Column | Type | Notes |
|---|---|---|
| otp_id | BIGINT UNSIGNED, PK | |
| target_type | VARCHAR(20), NN | USER / CLIENT |
| target_id | BIGINT UNSIGNED, NN | |
| destination | VARCHAR(150), NN | phone or email OTP was sent to (must be the value **on file**, not user-supplied, for account-linking cases) |
| purpose | VARCHAR(20), NN | LOGIN / REGISTER / ATTACH_LOGIN / RESET_PASSWORD |
| otp_code_hash | VARCHAR(255), NN | |
| expires_on | DATETIME, NN | |
| is_used | TINYINT(1), NN, default 0 | |
| attempt_count | TINYINT UNSIGNED, NN, default 0 | |
| created_on | DATETIME, NN | |

### ChannelServiceAccounts
*Service-level identities used by USSD gateway, WhatsApp webhook, and Website guest checkout to authenticate to the API (not tied to an individual person).*
| Column | Type | Notes |
|---|---|---|
| service_account_id | BIGINT UNSIGNED, PK | |
| channel | VARCHAR(20), NN, U | USSD / WHATSAPP / WEBSITE_GUEST |
| api_key_hash | VARCHAR(255), NN | |
| allowed_ip_range | VARCHAR(100) | CIDR, for USSD aggregator IP allowlisting |
| role_id | BIGINT UNSIGNED, NN, FK → Roles | points to CHANNEL_SERVICE role |
| is_active | TINYINT(1), NN, default 1 | |

### PotentialDuplicateClients
*Manually-flagged peer relationship between two **distinct** Clients rows (different id_no — e.g. a data-entry typo created two records for the same real person) that Support suspects are the same individual. Not used by the id_no-match self-service flow, since id_no is unique — that flow can never produce two rows for the same id_no. See `ClientLoginAttachRequests` below for the case that flow can actually hit.*
| Column | Type | Notes |
|---|---|---|
| duplicate_id | BIGINT UNSIGNED, PK | |
| client_id_a | BIGINT UNSIGNED, NN, FK → Clients | |
| client_id_b | BIGINT UNSIGNED, NN, FK → Clients | |
| flagged_by_user_id | BIGINT UNSIGNED, FK → Users, nullable | who noticed/flagged the suspected duplicate |
| status | VARCHAR(20), NN | PENDING / MERGED / REJECTED |
| flagged_on | DATETIME, NN | |
| resolved_by_user_id | BIGINT UNSIGNED, FK → Users | Support_Agent who resolves it |
| resolved_on | DATETIME | |

### ClientLoginAttachRequests
*Correction from earlier design: id_no is unique on Clients, so the self-service "attach login to existing client" flow can never create a second Clients row for the same id_no — there's no duplicate to speak of. What it CAN hit is the OTP-to-on-file-contact failing (stale phone/email). In that case the purchase still completes under the same client_id (identity is unambiguous — id_no already matched), but no login is granted, and this table records the failed attempt for Support to manually verify and resolve.*
| Column | Type | Notes |
|---|---|---|
| request_id | BIGINT UNSIGNED, PK | |
| client_id | BIGINT UNSIGNED, NN, FK → Clients | |
| attempted_phone | VARCHAR(20), nullable | phone typed during the failed attempt |
| attempted_email | VARCHAR(150), nullable | email typed during the failed attempt |
| status | VARCHAR(20), NN | PENDING / VERIFIED / REJECTED |
| flagged_on | DATETIME, NN | |
| resolved_by_user_id | BIGINT UNSIGNED, FK → Users, nullable | Support_Agent who resolves it |
| resolved_on | DATETIME, nullable | |

---

## 2. Insurance Catalog

### Underwriters
| Column | Type | Notes |
|---|---|---|
| underwriter_id | BIGINT UNSIGNED, PK | |
| name | VARCHAR(150), NN | e.g. Jubilee, Amaco |
| code | VARCHAR(20), NN, U | |
| contact_email | VARCHAR(150) | |
| contact_phone | VARCHAR(20) | |
| is_active | TINYINT(1), NN, default 1 | |
| dmvic_code | VARCHAR(50), nullable | reserved for future DMVIC integration — not populated yet |
| created_by | BIGINT UNSIGNED, FK → Users | Agent_admin |
| created_on | DATETIME, NN | |

### Products
| Column | Type | Notes |
|---|---|---|
| product_id | BIGINT UNSIGNED, PK | |
| name | VARCHAR(100), NN | Motor, Medical Individual/Family, Medical Corporate, Professional Indemnity, Travel, Domestic |
| code | VARCHAR(20), NN, U | |
| pricing_method | VARCHAR(20), NN | FIXED_MAPPING (Motor TPO) / FORMULA (Motor Comprehensive) / MANUAL_QUOTE (all others) |
| is_active | TINYINT(1), NN, default 1 | |

### MotorCategories
| Column | Type | Notes |
|---|---|---|
| motor_category_id | BIGINT UNSIGNED, PK | |
| product_id | BIGINT UNSIGNED, NN, FK → Products | |
| name | VARCHAR(50), NN | TPO / Comprehensive |

### PolicyLevels
*The DMVIC-style motor policy levels shared across all underwriters — both MotorVehicleClasses.policy_level_id and UnderwriterPolicyLevelNumber.policy_level_id reference this table. Fixed/seeded, not managed via the API.*
| Column | Type | Notes |
|---|---|---|
| policy_level_id | INT UNSIGNED, PK | 1-6, seeded: Class A - PSV Unmarked, Type B - Commercial Vehicle, Type C - Private Car, Type D - Motor Cycle, Type A - Taxi, Type D - PSV |
| name | VARCHAR(100), NN | |
| created_by | BIGINT UNSIGNED, FK → Users | |
| created_on | DATETIME, NN | |

### MotorVehicleClasses
| Column | Type | Notes |
|---|---|---|
| vehicle_class_id | BIGINT UNSIGNED, PK | |
| name | VARCHAR(100), NN, U | PSV-Bus, PSV-Matatu, PSV-Taxi/Tuk Tuk, PSV-Private Hire/Uber, Private, Motor Commercial: Own Goods/Institution/Prime Mover/Trailer/Tankers & Specified Trailer/General/Tractor, Motorcycle: Private/PSV |
| requires_tonnage | TINYINT(1), NN | 1 for Commercial classes, 0 otherwise |
| policy_level_id | INT UNSIGNED, nullable, FK → PolicyLevels | which DMVIC-style policy level this class falls under; NULL for PSV-Bus/PSV-Matatu (no level in source data) |

### Periods
*Lookup table for cover duration — modeled after the legacy Period reference table (id, code, name, status, isdelete, deleted_on).*
| Column | Type | Notes |
|---|---|---|
| period_id | BIGINT UNSIGNED, PK | |
| name | VARCHAR(50), NN, U | 1 Week, 2 Weeks, 1 Month, 6 Months, 1 Year |
| duration_days | INT UNSIGNED, NN | 7 / 14 / 30 / 182 / 365 — used to compute `Purchases.end_date` reliably (calendar months vary in length, so this avoids ambiguity) |
| dmvic_code | VARCHAR(50), nullable | reserved for future DMVIC integration — legacy table's `code` column looked like an external reference code, not a computed duration, so kept separate rather than derived |
| is_active | TINYINT(1), NN, default 1 | |
| isdeleted | TINYINT(1), NN, default 0 | |
| deleted_by | BIGINT UNSIGNED, FK → Users, nullable | |
| deleted_on | DATETIME, nullable | |

### TpoPriceMapping
| Column | Type | Notes |
|---|---|---|
| tpo_price_id | BIGINT UNSIGNED, PK | |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| vehicle_class_id | BIGINT UNSIGNED, NN, FK → MotorVehicleClasses | |
| period_id | BIGINT UNSIGNED, NN, FK → Periods | replaces raw period_months — matches legacy pattern of a coded period lookup rather than a plain number |
| carry_capacity | VARCHAR(50), nullable | seating/carrying capacity — used for PSV pricing |
| tonnage | DECIMAL(10,2), nullable | used for Commercial vehicle pricing (only when vehicle class `requires_tonnage = 1`) |
| price | DECIMAL(18,2), NN | |
| effective_from | DATE, NN | |
| effective_to | DATE | |
| is_active | TINYINT(1), NN, default 1 | |
| created_by | BIGINT UNSIGNED, FK → Users | Agent_admin |
| created_on | DATETIME, NN | |

*Note: `cover_type` from the legacy table was intentionally dropped — confirmed not needed since TPO vs Comprehensive is already separated structurally (this table is TPO-only; Comprehensive uses `ComprehensiveRateFormula`).*

### ComprehensiveRateFormula
| Column | Type | Notes |
|---|---|---|
| formula_id | BIGINT UNSIGNED, PK | |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| vehicle_class_id | BIGINT UNSIGNED, NN, FK → MotorVehicleClasses | |
| base_rate_percent | DECIMAL(5,2), NN | applied to vehicle value |
| min_premium | DECIMAL(18,2), NN | |
| effective_from | DATE, NN | |
| effective_to | DATE | |
| is_active | TINYINT(1), NN, default 1 | |

### ComprehensiveRateFactors
*Loadings/discounts applied on top of the base formula (anti-theft, no-claims bonus, etc.).*
| Column | Type | Notes |
|---|---|---|
| factor_id | BIGINT UNSIGNED, PK | |
| formula_id | BIGINT UNSIGNED, NN, FK → ComprehensiveRateFormula | |
| factor_type | VARCHAR(50), NN | ANTI_THEFT / NO_CLAIMS_BONUS / etc. |
| factor_percent | DECIMAL(5,2), NN | positive = loading, negative = discount |

---

## 3. Quote Workflow (Medical, PI, Travel, Domestic)

### QuoteRequests
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK | |
| product_id | BIGINT UNSIGNED, NN, FK → Products | |
| client_id | BIGINT UNSIGNED, FK → Clients, nullable | may not exist yet at quote stage |
| requested_by_user_id | BIGINT UNSIGNED, FK → Users, nullable | agent/support, null if self-service |
| channel | VARCHAR(20), NN | PORTAL / WEBSITE / USSD / WHATSAPP |
| status | VARCHAR(20), NN | PENDING / IN_PROGRESS / QUOTED / EXPIRED / CONVERTED |
| assigned_backoffice_user_id | BIGINT UNSIGNED, FK → Users, nullable | |
| created_on | DATETIME, NN | |

### QuoteRequestMedicalIndividual
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK, FK → QuoteRequests | |
| client_name | VARCHAR(150), NN | |
| client_dob | DATE, NN | |
| family_members_json | JSON | array of `{relationship, fullName, dateOfBirth}` - relationship is "Spouse" (at most one) or "Child" (any number), validated in the API before insert |
| id_no | VARCHAR(50), NN | |
| email | VARCHAR(150) | |
| phone | VARCHAR(20), NN | |

### QuoteRequestMedicalCorporate
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK, FK → QuoteRequests | |
| company_name | VARCHAR(150), NN | |
| phone | VARCHAR(20), NN | |
| email | VARCHAR(150), NN | |

### QuoteRequestProfessionalIndemnity
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK, FK → QuoteRequests | |
| client_or_company_name | VARCHAR(150), NN | |
| phone | VARCHAR(20), NN | |
| email | VARCHAR(150), NN | |
| profession | VARCHAR(100), NN | |
| proposal_form_status | VARCHAR(20) | redirected / submitted |

### QuoteRequestTravel
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK, FK → QuoteRequests | |
| client_name | VARCHAR(150), NN | |
| dob | DATE, NN | |
| kra_pin | VARCHAR(20) | |
| destination | VARCHAR(150), NN | |
| travel_date_from | DATE, NN | |
| travel_date_to | DATE, NN | |
| travelling_with_family | TINYINT(1), NN | |
| trip_type | VARCHAR(20), NN | VACATION / BUSINESS / SPORTS |

### QuoteRequestDomestic
| Column | Type | Notes |
|---|---|---|
| quote_request_id | BIGINT UNSIGNED, PK, FK → QuoteRequests | |
| *(fields TBD — flagged below)* | | |

### QuoteOffers
*Back office uploads one offer per underwriter against a quote request; client/agent selects one to convert.*
| Column | Type | Notes |
|---|---|---|
| quote_offer_id | BIGINT UNSIGNED, PK | |
| quote_request_id | BIGINT UNSIGNED, NN, FK → QuoteRequests | |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| premium_amount | DECIMAL(18,2), NN | |
| document_path | VARCHAR(255) | uploaded quote document |
| uploaded_by_user_id | BIGINT UNSIGNED, NN, FK → Users | |
| uploaded_on | DATETIME, NN | |
| status | VARCHAR(20), NN | ACTIVE / SELECTED / REJECTED / EXPIRED |

---

## 4. Vehicles

### Vehicles
*Master identity — one row per physical vehicle, deduped by reg_no/chassis_no. Owner = client_id.*
| Column | Type | Notes |
|---|---|---|
| vehicle_id | BIGINT UNSIGNED, PK | |
| client_id | BIGINT UNSIGNED, NN, FK → Clients | owner — one client, many vehicles |
| make | VARCHAR(100) | |
| model | VARCHAR(100) | |
| reg_no | VARCHAR(100), U | |
| chassis_no | VARCHAR(100), U | |
| engine_no | VARCHAR(100) | |
| yearofmanufacture | YEAR | |
| vehicle_type | VARCHAR(200) | |
| p_bodytype | VARCHAR(100) | |
| fueltype | VARCHAR(50) | |
| cubiccapacity | VARCHAR(100) | |
| color | VARCHAR(100) | |
| logbook | VARCHAR(100) | |
| created_by | BIGINT UNSIGNED, FK → Users | agent / agent_admin / support / client themselves |
| created_on | DATETIME, NN | |
| isdeleted | TINYINT(1), NN, default 0 | |
| deleted_by | BIGINT UNSIGNED, FK → Users | |
| deleted_on | DATETIME | |

### VehiclePurchaseSnapshot
*Fields that vary purchase-to-purchase (value, tonnage, etc.) — captured as-of the purchase date so history stays accurate even if the vehicle's current details change later.*
| Column | Type | Notes |
|---|---|---|
| snapshot_id | BIGINT UNSIGNED, PK | |
| vehicle_id | BIGINT UNSIGNED, NN, FK → Vehicles | |
| purchase_id | BIGINT UNSIGNED, NN, FK → Purchases | |
| vehicle_value | DECIMAL(18,2) | |
| tonnage | DECIMAL(10,2) | |
| licensedtocarry | BIGINT UNSIGNED | |
| antitheft | VARCHAR(50) | |
| risk | VARCHAR(100) | |
| amount | DECIMAL(18,2) | |
| created_on | DATETIME, NN | |

---

## 5. Purchases & Payments

### Purchases
| Column | Type | Notes |
|---|---|---|
| purchase_id | BIGINT UNSIGNED, PK | |
| product_id | BIGINT UNSIGNED, NN, FK → Products | |
| client_id | BIGINT UNSIGNED, NN, FK → Clients | who the cover belongs to |
| purchased_by_user_id | BIGINT UNSIGNED, FK → Users, nullable | staff/self who executed it |
| channel_service_account_id | BIGINT UNSIGNED, FK → ChannelServiceAccounts, nullable | set instead of purchased_by_user_id for USSD/WhatsApp/guest |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| quote_offer_id | BIGINT UNSIGNED, FK → QuoteOffers, nullable | set for manual-quote products |
| premium_amount | DECIMAL(18,2), NN | |
| period_id | BIGINT UNSIGNED, NN, FK → Periods | replaces the earlier period_months — consistent with the Periods table used for TPO pricing; `end_date` is computed from `Periods.duration_days` |
| start_date | DATE, NN | |
| end_date | DATE, NN | |
| policy_number | VARCHAR(50), U | |
| payment_status | VARCHAR(20), NN | PENDING / PAID / FAILED |
| status | VARCHAR(20), NN | ACTIVE / EXPIRED / CANCELLED |
| created_on | DATETIME, NN | |

### Payments
| Column | Type | Notes |
|---|---|---|
| payment_id | BIGINT UNSIGNED, PK | |
| purchase_id | BIGINT UNSIGNED, NN, FK → Purchases | |
| amount | DECIMAL(18,2), NN | |
| method | VARCHAR(20), NN | MPESA / CARD / BANK |
| payer_phone | VARCHAR(20) | |
| transaction_reference | VARCHAR(100) | |
| status | VARCHAR(20), NN | PENDING / SUCCESS / FAILED |
| initiated_on | DATETIME, NN | |
| completed_on | DATETIME | important for USSD: STK push completes async after session ends |

---

## 6. Commissions

### CommissionRates
*Default rate per product + underwriter.*
| Column | Type | Notes |
|---|---|---|
| rate_id | BIGINT UNSIGNED, PK | |
| product_id | BIGINT UNSIGNED, NN, FK → Products | |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| default_rate_percent | DECIMAL(5,2), NN | |
| effective_from | DATE, NN | |
| effective_to | DATE | |

### AgentCommissionOverrides
*Individually negotiated rate — takes precedence over the default when present.*
| Column | Type | Notes |
|---|---|---|
| override_id | BIGINT UNSIGNED, PK | |
| agent_user_id | BIGINT UNSIGNED, NN, FK → Users | |
| product_id | BIGINT UNSIGNED, NN, FK → Products | |
| underwriter_id | BIGINT UNSIGNED, NN, FK → Underwriters | |
| override_rate_percent | DECIMAL(5,2), NN | |
| effective_from | DATE, NN | |
| effective_to | DATE | |
| set_by_user_id | BIGINT UNSIGNED, NN, FK → Users | Agent_admin |
| created_on | DATETIME, NN | |

### AgentCommissions
*One row per purchase, only when purchased_by_user_id is an Agent or Agent_admin. No row for Support_Agent or self-service purchases.*
| Column | Type | Notes |
|---|---|---|
| commission_id | BIGINT UNSIGNED, PK | |
| purchase_id | BIGINT UNSIGNED, NN, U, FK → Purchases | |
| agent_user_id | BIGINT UNSIGNED, NN, FK → Users | |
| rate_percent_applied | DECIMAL(5,2), NN | resolved at time of purchase (override if present, else default) |
| cover_amount | DECIMAL(18,2), NN | |
| commission_amount | DECIMAL(18,2), NN | |
| status | VARCHAR(20), NN | ACCRUED / WITHDRAWN |
| withdrawal_id | BIGINT UNSIGNED, FK → CommissionWithdrawals, nullable | set when this specific commission row is reserved by / paid out via a withdrawal request — lets a withdrawal know exactly which rows it covers, and a rejected request release them back to the available pool |
| created_on | DATETIME, NN | |

### CommissionWithdrawals
| Column | Type | Notes |
|---|---|---|
| withdrawal_id | BIGINT UNSIGNED, PK | |
| agent_user_id | BIGINT UNSIGNED, NN, FK → Users | |
| amount | DECIMAL(18,2), NN | |
| status | VARCHAR(20), NN | REQUESTED / APPROVED / PAID / REJECTED |
| requested_on | DATETIME, NN | |
| processed_by_user_id | BIGINT UNSIGNED, FK → Users | |
| processed_on | DATETIME | |

---

## 7. Audit

### AuditLog
| Column | Type | Notes |
|---|---|---|
| audit_id | BIGINT UNSIGNED, PK | |
| actor_type | VARCHAR(20), NN | USER / CLIENT / CHANNEL_SERVICE — CLIENT covers self-service actions like a client verifying their own OTP |
| actor_id | BIGINT UNSIGNED, NN | |
| action | VARCHAR(100), NN | |
| entity | VARCHAR(100), NN | |
| entity_id | BIGINT UNSIGNED, NN | |
| old_value | JSON | |
| new_value | JSON | |
| created_on | DATETIME, NN | |

## 8. Portal Menus

*Admin Portal navigation - independent of Permissions/RolePermissions above. This controls what a role SEES in the sidebar, not what the API actually ALLOWS; the API keeps enforcing real permissions via `[Authorize(Policy = ...)]` regardless of what the portal shows or hides. Empty on a fresh install - rows get added as each Admin Portal screen is actually built.*

### Menus
| Column | Type | Notes |
|---|---|---|
| menu_id | BIGINT UNSIGNED, PK | |
| parent_menu_id | BIGINT UNSIGNED, nullable, FK → Menus | NULL = top-level. A top-level row is either a group header (url IS NULL, has children) or a direct link (url IS NOT NULL, no children) - same shape one level down |
| label | VARCHAR(100), NN | |
| icon | VARCHAR(50), nullable | Font Awesome class, e.g. `fa-home` - portal renders it, no markup stored here |
| url | VARCHAR(255), nullable | |
| sort_order | INT, NN, default 0 | |
| is_active | TINYINT(1), NN, default 1 | |
| created_by | BIGINT UNSIGNED, FK → Users | |
| created_on | DATETIME, NN | |

### RoleMenus
*Bare junction table, same shape as `RolePermissions` - a row's mere presence means that role can see that menu item; no separate `can_access` flag, since "no row" already means "no access."*
| Column | Type | Notes |
|---|---|---|
| role_id | BIGINT UNSIGNED, PK part, FK → Roles | |
| menu_id | BIGINT UNSIGNED, PK part, FK → Menus | |

---

## Key design decisions (for reference)

1. **RBAC enforced at the API layer** (ASP.NET policies), stored procedures stay data-access only.
2. **Channel authentication**: USSD/WhatsApp/Website-guest authenticate as `ChannelServiceAccounts` (IP allowlist + HMAC key for USSD, webhook signature for WhatsApp), not as individual users. The end user is identified by phone/ID number carried as data, not as the authenticated principal.
3. **Users vs Clients**: `Users` = anyone who can log in (staff + activated clients). `Clients` = everyone insured, whether or not they can log in. `Clients.user_id` is set only when login is granted.
4. **Identity linking rule**: when an existing Client (created without login) is matched by ID number during self-service registration, the OTP is sent to the contact info **already on file**, never to whatever the requester just typed — this prevents account takeover by anyone who merely knows someone else's ID number. The purchase always completes under that same `client_id` regardless of OTP outcome (id_no already resolved identity unambiguously); if the OTP can't be verified (stale on-file contact), only the *login grant* is withheld and the attempt is logged to `ClientLoginAttachRequests` for manual Support resolution — nothing is ever blocked, and no duplicate Clients row is ever created (id_no is unique, so that's structurally impossible).
5. **Vehicle snapshot pattern**: `Vehicles` holds durable identity (reg_no, chassis_no, etc.); `VehiclePurchaseSnapshot` freezes the varying fields (value, tonnage, etc.) per purchase so historical premiums/cover remain auditable even as the vehicle's current details change.
6. **Commission**: purely per-transaction, tied to whoever executed that specific purchase (`purchased_by_user_id`). No lasting "ownership" of a client for commission purposes. Rate = agent-specific override if one exists for that product/underwriter, else the product/underwriter default.

## Open items

- **QuoteRequestDomestic** fields not yet specified — need the field list for Domestic Insurance.
- **Claims** — confirmed out of scope for this phase (per earlier discussion) unless you want it reserved for now.
- Confirm whether Agent_admin also earns commission (schema currently allows it, since Agent_admin can also execute purchases on behalf of clients).
