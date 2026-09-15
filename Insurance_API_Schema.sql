-- =====================================================================
-- Insurance Platform — Schema DDL (v1)
-- MySQL 8.0+ / InnoDB / utf8mb4
-- Matches Insurance_API_Schema_Design.md
-- =====================================================================

-- Dropping first makes this script safely re-runnable during development
-- (schema is still evolving). Remove this line once real data exists.
DROP DATABASE IF EXISTS insurance_platform;

CREATE DATABASE IF NOT EXISTS insurance_platform
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE insurance_platform;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 1. ROLES, USERS, CLIENTS (AUTH & RBAC)
-- =====================================================================

CREATE TABLE Roles (
    role_id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_code           VARCHAR(20)  NOT NULL,
    name                VARCHAR(50)  NOT NULL,
    description         VARCHAR(255) NULL,
    is_active           TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT uq_roles_code UNIQUE (role_code),
    CONSTRAINT uq_roles_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Permissions (
    permission_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code                VARCHAR(100) NOT NULL,
    description         VARCHAR(255) NULL,
    CONSTRAINT uq_permissions_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE RolePermissions (
    role_id             BIGINT UNSIGNED NOT NULL,
    permission_id       BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role       FOREIGN KEY (role_id)       REFERENCES Roles(role_id)             ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES Permissions(permission_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Users (
    user_id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id                BIGINT UNSIGNED NOT NULL,
    id_no                  VARCHAR(50)  NOT NULL,
    full_name              VARCHAR(150) NOT NULL,
    email                  VARCHAR(150) NULL,
    phone                  VARCHAR(20)  NOT NULL,
    password_hash          VARCHAR(255) NOT NULL,
    status                 VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    must_change_password   TINYINT(1)   NOT NULL DEFAULT 0,
    -- Lockout tracking. failed_login_attempts resets to 0 on any successful
    -- login (usp_User_RecordSuccessfulLogin); usp_User_RecordFailedLogin
    -- increments it on a wrong password and, once it hits the threshold,
    -- flips status to 'LOCKED' and sets locked_until. usp_User_GetByIdNoForLogin
    -- auto-reactivates the account (status back to ACTIVE, counters cleared)
    -- the moment someone tries to log in again after locked_until has passed -
    -- no admin action needed for the common case of a genuine user who just
    -- mistyped their password repeatedly.
    failed_login_attempts  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    locked_until           DATETIME NULL,
    created_by             BIGINT UNSIGNED NULL,
    created_on             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_on          DATETIME NULL,
    isdeleted              TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT uq_users_id_no UNIQUE (id_no),
    CONSTRAINT fk_users_role        FOREIGN KEY (role_id)    REFERENCES Roles(role_id)  ON DELETE RESTRICT,
    CONSTRAINT fk_users_created_by  FOREIGN KEY (created_by) REFERENCES Users(user_id)  ON DELETE SET NULL,
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE','INACTIVE','LOCKED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_users_role ON Users(role_id);

CREATE TABLE Clients (
    client_id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_no                    VARCHAR(50)  NOT NULL,
    full_name                VARCHAR(150) NOT NULL,
    dob                      DATE NULL,
    email                    VARCHAR(150) NULL,
    phone                    VARCHAR(20)  NOT NULL,
    address                  VARCHAR(255) NULL,
    kra_pin                  VARCHAR(20)  NULL,
    user_id                  BIGINT UNSIGNED NULL,
    registered_by_user_id    BIGINT UNSIGNED NULL,
    registration_channel     VARCHAR(20)  NOT NULL,
    created_on               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    isdeleted                TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT uq_clients_id_no UNIQUE (id_no),
    CONSTRAINT uq_clients_user_id UNIQUE (user_id),
    CONSTRAINT fk_clients_user          FOREIGN KEY (user_id)               REFERENCES Users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_clients_registered_by FOREIGN KEY (registered_by_user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_clients_channel CHECK (registration_channel IN ('PORTAL','USSD','WHATSAPP','WEBSITE','MOBILE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_clients_phone ON Clients(phone);

CREATE TABLE OtpVerifications (
    otp_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    target_type      VARCHAR(20)  NOT NULL,
    target_id        BIGINT UNSIGNED NOT NULL,
    destination      VARCHAR(150) NOT NULL,
    purpose          VARCHAR(20)  NOT NULL,
    otp_code_hash    VARCHAR(255) NOT NULL,
    expires_on       DATETIME NOT NULL,
    is_used          TINYINT(1)   NOT NULL DEFAULT 0,
    attempt_count    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    created_on       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_otp_target_type CHECK (target_type IN ('USER','CLIENT')),
    CONSTRAINT chk_otp_purpose CHECK (purpose IN ('LOGIN','REGISTER','ATTACH_LOGIN','RESET_PASSWORD'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_otp_target ON OtpVerifications(target_type, target_id);

CREATE TABLE ChannelServiceAccounts (
    service_account_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    channel              VARCHAR(20)  NOT NULL,
    api_key_hash         VARCHAR(255) NOT NULL,
    allowed_ip_range      VARCHAR(100) NULL,
    role_id               BIGINT UNSIGNED NOT NULL,
    is_active             TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT uq_channel_accounts_channel UNIQUE (channel),
    CONSTRAINT fk_channel_accounts_role FOREIGN KEY (role_id) REFERENCES Roles(role_id) ON DELETE RESTRICT
    -- NOTE: this table used to also have
    -- "CONSTRAINT chk_channel_accounts_channel CHECK (channel IN ('USSD','WHATSAPP','WEBSITE_GUEST'))"
    -- here, hard-limiting channel to those 3 fixed values. Dropped so a
    -- SuperAdmin can register a brand-new channel integration later (see
    -- usp_ChannelServiceAccount_Create / ChannelAccountsController)
    -- without a schema migration every time. If you already have a live
    -- database with this constraint, you must drop it there too - it
    -- won't disappear just because CREATE TABLE IF NOT EXISTS is a no-op
    -- on an existing table:
    --   ALTER TABLE ChannelServiceAccounts DROP CHECK chk_channel_accounts_channel;
    -- channel is still validated at the API layer (uppercase,
    -- alphanumeric/underscore, max 20 chars) - this only removes the
    -- fixed-enum restriction, not all validation.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Manually-flagged peer relationship between two DISTINCT Clients rows
-- (different id_no — e.g. a typo created two records for the same real
-- person) that Support suspects are the same individual and may merge.
-- NOTE: this is NOT used for the id_no-match self-service login flow —
-- id_no is unique, so that flow can never produce two Clients rows for
-- the same id_no in the first place. See ClientLoginAttachRequests below
-- for the "stale on-file contact" case that flow can hit.
CREATE TABLE PotentialDuplicateClients (
    duplicate_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id_a           BIGINT UNSIGNED NOT NULL,
    client_id_b            BIGINT UNSIGNED NOT NULL,
    flagged_by_user_id       BIGINT UNSIGNED NULL,
    status                     VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    flagged_on                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_by_user_id           BIGINT UNSIGNED NULL,
    resolved_on                     DATETIME NULL,
    CONSTRAINT fk_dup_client_a     FOREIGN KEY (client_id_a)        REFERENCES Clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_dup_client_b     FOREIGN KEY (client_id_b)        REFERENCES Clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_dup_flagged_by   FOREIGN KEY (flagged_by_user_id) REFERENCES Users(user_id)     ON DELETE SET NULL,
    CONSTRAINT fk_dup_resolved_by  FOREIGN KEY (resolved_by_user_id) REFERENCES Users(user_id)     ON DELETE SET NULL,
    CONSTRAINT chk_dup_status CHECK (status IN ('PENDING','MERGED','REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- The id_no-match self-service flow: when an existing Client (created
-- without login) is matched by id_no and the OTP sent to the on-file
-- phone/email can't be verified (e.g. stale contact info), the purchase
-- still completes under the SAME client_id (identity is unambiguous —
-- id_no already matched), but no login is granted. This table records
-- that a login-attach attempt failed so Support can manually verify the
-- person and either update the on-file contact or reject the attempt.
CREATE TABLE ClientLoginAttachRequests (
    request_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id           BIGINT UNSIGNED NOT NULL,
    attempted_phone       VARCHAR(20) NULL,
    attempted_email         VARCHAR(150) NULL,
    status                    VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    flagged_on                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_by_user_id          BIGINT UNSIGNED NULL,
    resolved_on                    DATETIME NULL,
    CONSTRAINT fk_clar_client      FOREIGN KEY (client_id)           REFERENCES Clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_clar_resolved_by FOREIGN KEY (resolved_by_user_id) REFERENCES Users(user_id)     ON DELETE SET NULL,
    CONSTRAINT chk_clar_status CHECK (status IN ('PENDING','VERIFIED','REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_clar_client ON ClientLoginAttachRequests(client_id);

-- =====================================================================
-- 2. INSURANCE CATALOG
-- =====================================================================

-- The DMVIC-style motor policy levels shared across all underwriters (Class
-- A - PSV Unmarked, Type B - Commercial Vehicle, etc.) - both
-- MotorVehicleClasses.policy_level_id and UnderwriterPolicyLevelNumber.policy_level_id
-- point here. Fixed/seeded reference data, not managed via the API, same as
-- MotorVehicleClasses itself.
CREATE TABLE PolicyLevels (
    policy_level_id  INT UNSIGNED PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    created_by         BIGINT UNSIGNED NULL,
    created_on          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_policylevel_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO PolicyLevels (policy_level_id, name, created_by) VALUES
    (1, 'Class A - PSV Unmarked', 1),
    (2, 'Type B - Commercial Vehicle', 1),
    (3, 'Type C - Private Car', 1),
    (4, 'Type D - Motor Cycle', 1),
    (5, 'Type A - Taxi', 1),
    (6, 'Type D - PSV', 1);

CREATE TABLE Underwriters (
    underwriter_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(150) NOT NULL,
    code               VARCHAR(20)  NOT NULL,
    contact_email      VARCHAR(150) NULL,
    contact_phone      VARCHAR(20)  NULL,
    is_active          TINYINT(1)   NOT NULL DEFAULT 1,
    dmvic_code         VARCHAR(50)  NULL COMMENT 'Reserved for future DMVIC integration',
    -- FIXED = this underwriter issues one real, reused policy_number per
    -- policy_level (see UnderwriterPolicyLevelNumber below) - the same
    -- number is stamped on every certificate sold at that level, it is
    -- NOT unique per sale. CHANGE = no fixed pre-set number; today that
    -- still means usp_Purchase_Create's own auto-generated "POL-..."
    -- number applies, same as every underwriter before this feature
    -- existed. Defaults to CHANGE so registering a brand-new underwriter
    -- never has to think about this unless FIXED is actually the case.
    policy_type        VARCHAR(20)  NOT NULL DEFAULT 'CHANGE',
    created_by         BIGINT UNSIGNED NULL,
    created_on         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_underwriters_code UNIQUE (code),
    CONSTRAINT fk_underwriters_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_underwriters_policy_type CHECK (policy_type IN ('FIXED','CHANGE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE Products (
    product_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    code               VARCHAR(20)  NOT NULL,
    pricing_method     VARCHAR(20)  NOT NULL,
    is_active          TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT uq_products_code UNIQUE (code),
    CONSTRAINT chk_products_pricing_method CHECK (pricing_method IN ('FIXED_MAPPING','FORMULA','MANUAL_QUOTE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE MotorCategories (
    motor_category_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id           BIGINT UNSIGNED NOT NULL,
    name                  VARCHAR(50) NOT NULL,
    CONSTRAINT fk_motorcat_product FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE MotorVehicleClasses (
    vehicle_class_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                 VARCHAR(100) NOT NULL,
    requires_tonnage     TINYINT(1) NOT NULL DEFAULT 0,
    -- Which underwriter policy_level (see PolicyLevels/UnderwriterPolicyLevelNumber
    -- below) this vehicle class falls under, e.g. so a Private purchase
    -- from a FIXED-policy_type underwriter knows which one of that
    -- underwriter's reused numbers to stamp on the sale. Nullable - two
    -- classes (PSV-BUS, PSV-MATATU) genuinely have no level per the source
    -- data and stay NULL; every other class is mapped below.
    policy_level_id       INT UNSIGNED NULL,
    CONSTRAINT uq_vehicleclass_name UNIQUE (name),
    CONSTRAINT fk_vehicleclass_policylevel FOREIGN KEY (policy_level_id) REFERENCES PolicyLevels(policy_level_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Cover-duration lookup, modeled after the legacy Period reference table
-- (id, code, name, status, isdelete, deleted_on). "code" in the legacy
-- table looked like an external/DMVIC reference code rather than a
-- computed duration, so it's kept as a separate nullable dmvic_code
-- column rather than derived from name.
CREATE TABLE Periods (
    period_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(50) NOT NULL,
    duration_days       INT UNSIGNED NOT NULL COMMENT 'Used to compute Purchases.end_date = start_date + duration_days',
    dmvic_code          VARCHAR(50) NULL COMMENT 'Reserved for future DMVIC integration',
    is_active            TINYINT(1) NOT NULL DEFAULT 1,
    isdeleted             TINYINT(1) NOT NULL DEFAULT 0,
    deleted_by             BIGINT UNSIGNED NULL,
    deleted_on               DATETIME NULL,
    CONSTRAINT uq_periods_name UNIQUE (name),
    CONSTRAINT fk_periods_deleted_by FOREIGN KEY (deleted_by) REFERENCES Users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE TpoPriceMapping (
    tpo_price_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id       BIGINT UNSIGNED NOT NULL,
    vehicle_class_id     BIGINT UNSIGNED NOT NULL,
    period_id             BIGINT UNSIGNED NOT NULL,
    carry_capacity          VARCHAR(50) NULL COMMENT 'Seating/carrying capacity — used for PSV pricing',
    tonnage                   DECIMAL(10,2) NULL COMMENT 'Used for Commercial vehicle pricing',
    price                      DECIMAL(18,2) NOT NULL,
    effective_from              DATE NOT NULL,
    effective_to                  DATE NULL,
    is_active                      TINYINT(1) NOT NULL DEFAULT 1,
    created_by                      BIGINT UNSIGNED NULL,
    created_on                        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tpo_underwriter  FOREIGN KEY (underwriter_id)   REFERENCES Underwriters(underwriter_id)     ON DELETE RESTRICT,
    CONSTRAINT fk_tpo_vehicleclass FOREIGN KEY (vehicle_class_id) REFERENCES MotorVehicleClasses(vehicle_class_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tpo_period       FOREIGN KEY (period_id)        REFERENCES Periods(period_id)               ON DELETE RESTRICT,
    CONSTRAINT fk_tpo_created_by   FOREIGN KEY (created_by)       REFERENCES Users(user_id)                   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_tpo_lookup ON TpoPriceMapping(underwriter_id, vehicle_class_id, period_id, is_active);

CREATE TABLE ComprehensiveRateFormula (
    formula_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id        BIGINT UNSIGNED NOT NULL,
    vehicle_class_id      BIGINT UNSIGNED NOT NULL,
    base_rate_percent      DECIMAL(5,2) NOT NULL,
    min_premium             DECIMAL(18,2) NOT NULL,
    effective_from          DATE NOT NULL,
    effective_to            DATE NULL,
    is_active                TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_comp_underwriter  FOREIGN KEY (underwriter_id)   REFERENCES Underwriters(underwriter_id)     ON DELETE RESTRICT,
    CONSTRAINT fk_comp_vehicleclass FOREIGN KEY (vehicle_class_id) REFERENCES MotorVehicleClasses(vehicle_class_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE ComprehensiveRateFactors (
    factor_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    formula_id        BIGINT UNSIGNED NOT NULL,
    factor_type        VARCHAR(50) NOT NULL,
    factor_percent      DECIMAL(5,2) NOT NULL,
    CONSTRAINT fk_factor_formula FOREIGN KEY (formula_id) REFERENCES ComprehensiveRateFormula(formula_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- 3. QUOTE WORKFLOW (MEDICAL, PI, TRAVEL, DOMESTIC)
-- =====================================================================

CREATE TABLE QuoteRequests (
    quote_request_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Short, external-facing tracking code (e.g. "MI-7F3K2A") - generated
    -- once at INSERT time by each usp_QuoteRequest<Type>_Create proc (see
    -- Insurance_API_StoredProcs_Quotes.sql). This is what gets shown to
    -- users/support instead of quote_request_id - the raw auto-increment
    -- id stays the real primary key for every FK/join, unchanged.
    ref_no                       VARCHAR(20) NULL,
    product_id                  BIGINT UNSIGNED NOT NULL,
    client_id                    BIGINT UNSIGNED NULL,
    requested_by_user_id        BIGINT UNSIGNED NULL,
    channel                      VARCHAR(20) NOT NULL,
    status                        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    assigned_backoffice_user_id  BIGINT UNSIGNED NULL,
    created_on                   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_qr_ref_no      UNIQUE (ref_no),
    CONSTRAINT fk_qr_product     FOREIGN KEY (product_id)                 REFERENCES Products(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_qr_client      FOREIGN KEY (client_id)                  REFERENCES Clients(client_id)   ON DELETE SET NULL,
    CONSTRAINT fk_qr_requested_by FOREIGN KEY (requested_by_user_id)      REFERENCES Users(user_id)       ON DELETE SET NULL,
    CONSTRAINT fk_qr_assigned    FOREIGN KEY (assigned_backoffice_user_id) REFERENCES Users(user_id)      ON DELETE SET NULL,
    CONSTRAINT chk_qr_channel CHECK (channel IN ('PORTAL','WEBSITE','USSD','WHATSAPP')),
    CONSTRAINT chk_qr_status CHECK (status IN ('PENDING','IN_PROGRESS','QUOTED','EXPIRED','CONVERTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_qr_status ON QuoteRequests(status);
CREATE INDEX idx_qr_client ON QuoteRequests(client_id);

CREATE TABLE QuoteRequestMedicalIndividual (
    quote_request_id     BIGINT UNSIGNED PRIMARY KEY,
    -- Confirmed field list (see medical_individual_fields_migration.sql):
    -- 1. Customer Information: id_no, first_name, last_name, other_names, email, mobile_number
    first_name             VARCHAR(80) NOT NULL,
    last_name              VARCHAR(80) NOT NULL,
    other_names            VARCHAR(150) NULL,
    -- Array of {relationship, fullName, dateOfBirth} - relationship is
    -- "Spouse" (at most one) or "Child" (any number), enforced by
    -- QuoteRequestsController before this is ever written, not by a DB
    -- constraint. NULL/empty array = individual-only, no dependants.
    family_members_json     JSON NULL,
    id_no                    VARCHAR(50) NOT NULL,
    -- Required on every quote type (client-received + offers-comparison emails need a
    -- real address to send to). See quote_requests_require_idno_email_migration.sql
    email                    VARCHAR(150) NOT NULL,
    mobile_number            VARCHAR(20) NOT NULL,
    -- 2. Coverage Details
    inpatient_limit          DECIMAL(18,2) NOT NULL,
    -- 3. Optional Benefits - limits only populated when the benefit flag is on;
    -- Maternity has no limit (yes/no only).
    has_outpatient           TINYINT(1) NOT NULL DEFAULT 0,
    outpatient_limit         DECIMAL(18,2) NULL,
    has_dental               TINYINT(1) NOT NULL DEFAULT 0,
    dental_limit             DECIMAL(18,2) NULL,
    has_maternity            TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_qrmi_request FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE QuoteRequestMedicalCorporate (
    quote_request_id     BIGINT UNSIGNED PRIMARY KEY,
    -- The ID number of the person making this request on the company's
    -- behalf (not a company registration number) - added alongside every
    -- other quote type's id_no so every QuoteRequests row can be traced
    -- back to one real, identifiable requester.
    id_no                    VARCHAR(50) NOT NULL,
    company_name            VARCHAR(150) NOT NULL,
    phone                    VARCHAR(20) NOT NULL,
    email                    VARCHAR(150) NOT NULL,
    CONSTRAINT fk_qrmc_request FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE QuoteRequestProfessionalIndemnity (
    quote_request_id       BIGINT UNSIGNED PRIMARY KEY,
    -- Same "requester's own id_no" convention as QuoteRequestMedicalCorporate above.
    id_no                     VARCHAR(50) NOT NULL,
    client_or_company_name   VARCHAR(150) NOT NULL,
    phone                     VARCHAR(20) NOT NULL,
    email                     VARCHAR(150) NOT NULL,
    profession                 VARCHAR(100) NOT NULL,
    proposal_form_status       VARCHAR(20) NULL,
    CONSTRAINT fk_qrpi_request FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE QuoteRequestTravel (
    quote_request_id       BIGINT UNSIGNED PRIMARY KEY,
    -- id_no/email both added - Travel previously had neither (only
    -- kra_pin, which is optional and not the same thing as a national ID).
    id_no                     VARCHAR(50) NOT NULL,
    email                     VARCHAR(150) NOT NULL,
    client_name               VARCHAR(150) NOT NULL,
    dob                        DATE NOT NULL,
    kra_pin                     VARCHAR(20) NULL,
    destination                 VARCHAR(150) NOT NULL,
    travel_date_from             DATE NOT NULL,
    travel_date_to               DATE NOT NULL,
    travelling_with_family       TINYINT(1) NOT NULL DEFAULT 0,
    trip_type                     VARCHAR(20) NOT NULL,
    CONSTRAINT fk_qrt_request FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE CASCADE,
    CONSTRAINT chk_qrt_trip_type CHECK (trip_type IN ('VACATION','BUSINESS','SPORTS'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- NOTE: Domestic Insurance field list not yet confirmed.
-- Placeholder detail table below — extend/alter once fields are provided.
CREATE TABLE QuoteRequestDomestic (
    quote_request_id   BIGINT UNSIGNED PRIMARY KEY,
    -- id_no/email pulled out of the still-unconfirmed details_json blob and
    -- made real, required columns - these two are needed by every quote
    -- type now (client-received/offers emails), independent of whatever
    -- the rest of Domestic's field list ends up being.
    id_no                  VARCHAR(50) NOT NULL,
    email                  VARCHAR(150) NOT NULL,
    details_json          JSON NULL COMMENT 'TEMPORARY holding field until Domestic Insurance fields are confirmed',
    CONSTRAINT fk_qrd_request FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE QuoteOffers (
    quote_offer_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quote_request_id       BIGINT UNSIGNED NOT NULL,
    underwriter_id           BIGINT UNSIGNED NOT NULL,
    premium_amount            DECIMAL(18,2) NOT NULL,
    document_path              VARCHAR(255) NULL,
    uploaded_by_user_id        BIGINT UNSIGNED NOT NULL,
    uploaded_on                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status                       VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    -- Soft delete, same convention as Users/Clients/Vehicles (isdeleted flag,
    -- not a hard DELETE) - lets a mistakenly-added offer be removed from the
    -- back office's grid without losing the audit trail of it ever existing.
    isdeleted                    TINYINT(1) NOT NULL DEFAULT 0,
    deleted_by                   BIGINT UNSIGNED NULL,
    deleted_on                   DATETIME NULL,
    CONSTRAINT fk_qo_request     FOREIGN KEY (quote_request_id) REFERENCES QuoteRequests(quote_request_id) ON DELETE RESTRICT,
    CONSTRAINT fk_qo_underwriter FOREIGN KEY (underwriter_id)   REFERENCES Underwriters(underwriter_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_qo_uploaded_by FOREIGN KEY (uploaded_by_user_id) REFERENCES Users(user_id)               ON DELETE RESTRICT,
    CONSTRAINT fk_qo_deleted_by  FOREIGN KEY (deleted_by)          REFERENCES Users(user_id)               ON DELETE RESTRICT,
    CONSTRAINT chk_qo_status CHECK (status IN ('ACTIVE','SELECTED','REJECTED','EXPIRED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_qo_request ON QuoteOffers(quote_request_id);

-- =====================================================================
-- 4. VEHICLES
-- =====================================================================

CREATE TABLE Vehicles (
    vehicle_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id          BIGINT UNSIGNED NOT NULL,
    make                VARCHAR(100) NULL,
    model                VARCHAR(100) NULL,
    reg_no                VARCHAR(100) NULL,
    chassis_no            VARCHAR(100) NULL,
    engine_no              VARCHAR(100) NULL,
    yearofmanufacture       YEAR NULL,
    vehicle_type             VARCHAR(200) NULL,
    p_bodytype                VARCHAR(100) NULL,
    fueltype                   VARCHAR(50) NULL,
    cubiccapacity                VARCHAR(100) NULL,
    color                          VARCHAR(100) NULL,
    logbook                         VARCHAR(100) NULL,
    created_by                       BIGINT UNSIGNED NULL,
    created_on                        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    isdeleted                          TINYINT(1) NOT NULL DEFAULT 0,
    deleted_by                          BIGINT UNSIGNED NULL,
    deleted_on                           DATETIME NULL,
    CONSTRAINT uq_vehicles_reg_no UNIQUE (reg_no),
    CONSTRAINT uq_vehicles_chassis_no UNIQUE (chassis_no),
    CONSTRAINT fk_vehicles_client     FOREIGN KEY (client_id)   REFERENCES Clients(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_vehicles_created_by FOREIGN KEY (created_by)  REFERENCES Users(user_id)     ON DELETE SET NULL,
    CONSTRAINT fk_vehicles_deleted_by FOREIGN KEY (deleted_by)  REFERENCES Users(user_id)     ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_vehicles_client ON Vehicles(client_id);

-- =====================================================================
-- 5. PURCHASES & PAYMENTS
-- =====================================================================

CREATE TABLE Purchases (
    purchase_id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id                     BIGINT UNSIGNED NOT NULL,
    client_id                       BIGINT UNSIGNED NOT NULL,
    purchased_by_user_id             BIGINT UNSIGNED NULL,
    channel_service_account_id        BIGINT UNSIGNED NULL,
    underwriter_id                     BIGINT UNSIGNED NOT NULL,
    quote_offer_id                      BIGINT UNSIGNED NULL,
    premium_amount                       DECIMAL(18,2) NOT NULL,
    period_id                             BIGINT UNSIGNED NOT NULL,
    start_date                             DATE NOT NULL,
    end_date                                DATE NOT NULL,
    policy_number                            VARCHAR(50) NULL,
    payment_status                            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    status                                     VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_on                                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchases_policy_number UNIQUE (policy_number),
    CONSTRAINT fk_purchases_product     FOREIGN KEY (product_id)     REFERENCES Products(product_id)     ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_client      FOREIGN KEY (client_id)      REFERENCES Clients(client_id)       ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_purchased_by FOREIGN KEY (purchased_by_user_id) REFERENCES Users(user_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_channel_acct FOREIGN KEY (channel_service_account_id) REFERENCES ChannelServiceAccounts(service_account_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchases_underwriter FOREIGN KEY (underwriter_id) REFERENCES Underwriters(underwriter_id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_quote_offer FOREIGN KEY (quote_offer_id) REFERENCES QuoteOffers(quote_offer_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchases_period      FOREIGN KEY (period_id)      REFERENCES Periods(period_id)       ON DELETE RESTRICT,
    CONSTRAINT chk_purchases_payment_status CHECK (payment_status IN ('PENDING','PAID','FAILED')),
    CONSTRAINT chk_purchases_status CHECK (status IN ('ACTIVE','EXPIRED','CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_purchases_client ON Purchases(client_id);
CREATE INDEX idx_purchases_purchased_by ON Purchases(purchased_by_user_id);
CREATE INDEX idx_purchases_underwriter ON Purchases(underwriter_id);
CREATE INDEX idx_purchases_status ON Purchases(status);

CREATE TABLE VehiclePurchaseSnapshot (
    snapshot_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id             BIGINT UNSIGNED NOT NULL,
    purchase_id              BIGINT UNSIGNED NOT NULL,
    vehicle_value              DECIMAL(18,2) NULL,
    tonnage                      DECIMAL(10,2) NULL,
    licensedtocarry                BIGINT UNSIGNED NULL,
    antitheft                        VARCHAR(50) NULL,
    risk                               VARCHAR(100) NULL,
    amount                               DECIMAL(18,2) NULL,
    created_on                            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vps_vehicle  FOREIGN KEY (vehicle_id)  REFERENCES Vehicles(vehicle_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_vps_purchase FOREIGN KEY (purchase_id) REFERENCES Purchases(purchase_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_vps_vehicle ON VehiclePurchaseSnapshot(vehicle_id);
CREATE INDEX idx_vps_purchase ON VehiclePurchaseSnapshot(purchase_id);

CREATE TABLE Payments (
    payment_id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_id               BIGINT UNSIGNED NOT NULL,
    amount                       DECIMAL(18,2) NOT NULL,
    method                         VARCHAR(20) NOT NULL,
    payer_phone                     VARCHAR(20) NULL,
    transaction_reference             VARCHAR(100) NULL,
    gateway_reference                 VARCHAR(100) NULL,   -- Daraja CheckoutRequestID / C2B reference echoed by webhook callbacks
    status                              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    initiated_on                         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_on                          DATETIME NULL,
    CONSTRAINT fk_payments_purchase FOREIGN KEY (purchase_id) REFERENCES Purchases(purchase_id) ON DELETE RESTRICT,
    CONSTRAINT chk_payments_method CHECK (method IN ('MPESA','CARD','BANK')),
    CONSTRAINT chk_payments_status CHECK (status IN ('PENDING','SUCCESS','FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_payments_purchase ON Payments(purchase_id);
CREATE INDEX idx_payments_reference ON Payments(transaction_reference);
CREATE INDEX idx_payments_gateway_reference ON Payments(gateway_reference);

-- =====================================================================
-- 5a. UNDERWRITER POLICY LEVEL NUMBER
-- =====================================================================
-- ONE fixed, REUSED policy/certificate number per (underwriter,
-- policy_level) - not a consumable pool. Only meaningful for
-- Underwriters.policy_type = 'FIXED': that underwriter stamps the exact
-- same number on every certificate sold at a given level, e.g. every
-- Private-class TPO sale through them uses the one number registered
-- here for (that underwriter, Private's policy_level) - no per-sale
-- uniqueness, no "running out." (An earlier version of this feature
-- modeled it as a consumable pool with is_used/used_by_purchase_id - that
-- was wrong; this replaces it entirely.)
--
-- policy_level_id is a plain integer (not yet a foreign key into
-- MotorVehicleClasses) - the underwriter's own DMVIC-style level
-- categorization. MotorVehicleClasses.policy_level_id (added just above)
-- is how a given vehicle class says which level it falls under; that
-- mapping isn't populated yet, so nothing consumes this table
-- automatically during Purchase creation - it's a standalone registry
-- until that mapping is filled in and usp_Purchase_Create is updated to
-- use it.
CREATE TABLE UnderwriterPolicyLevelNumber (
    id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    underwriter_id           BIGINT UNSIGNED NOT NULL,
    policy_level_id             INT UNSIGNED NOT NULL,
    policy_number                  VARCHAR(50) NOT NULL,
    created_by                       BIGINT UNSIGNED NULL,
    created_on                         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    isdeleted                            TINYINT(1) NOT NULL DEFAULT 0,
    deleted_on                             DATETIME NULL,
    deleted_by                               BIGINT UNSIGNED NULL,
    CONSTRAINT uq_upln_underwriter_level UNIQUE (underwriter_id, policy_level_id),
    CONSTRAINT fk_upln_underwriter FOREIGN KEY (underwriter_id) REFERENCES Underwriters(underwriter_id) ON DELETE RESTRICT,
    CONSTRAINT fk_upln_policylevel FOREIGN KEY (policy_level_id) REFERENCES PolicyLevels(policy_level_id) ON DELETE RESTRICT,
    CONSTRAINT fk_upln_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_upln_deleted_by FOREIGN KEY (deleted_by) REFERENCES Users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- 6. COMMISSIONS
-- =====================================================================

-- Commission belongs to the AGENT, not to any product/underwriter
-- combination - one active flat percentage per agent, applied to every
-- purchase they execute regardless of what product or underwriter it's
-- through. (Earlier version of this schema had a per-product+underwriter
-- CommissionRates default table with per-agent overrides on top of it -
-- dropped entirely; this table IS the rate now, not an override of
-- anything, hence the name change from AgentCommissionOverrides.)
CREATE TABLE AgentCommissionRates (
    rate_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    agent_user_id        BIGINT UNSIGNED NOT NULL,
    rate_percent            DECIMAL(5,2) NOT NULL,
    effective_from             DATE NOT NULL,
    effective_to                 DATE NULL,
    set_by_user_id                  BIGINT UNSIGNED NOT NULL,
    created_on                         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_acr_agent   FOREIGN KEY (agent_user_id)   REFERENCES Users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acr_set_by  FOREIGN KEY (set_by_user_id)  REFERENCES Users(user_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_acr_agent ON AgentCommissionRates(agent_user_id);

CREATE TABLE AgentCommissions (
    commission_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_id              BIGINT UNSIGNED NOT NULL,
    agent_user_id              BIGINT UNSIGNED NOT NULL,
    rate_percent_applied         DECIMAL(5,2) NOT NULL,
    cover_amount                   DECIMAL(18,2) NOT NULL,
    commission_amount                DECIMAL(18,2) NOT NULL,
    status                             VARCHAR(20) NOT NULL DEFAULT 'ACCRUED',
    withdrawal_id                        BIGINT UNSIGNED NULL COMMENT 'Set once this commission is reserved by / paid out via a CommissionWithdrawals request — see below for the FK, added after that table exists',
    created_on                           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_agentcomm_purchase UNIQUE (purchase_id),
    CONSTRAINT fk_ac_purchase FOREIGN KEY (purchase_id)   REFERENCES Purchases(purchase_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ac_agent    FOREIGN KEY (agent_user_id) REFERENCES Users(user_id)         ON DELETE RESTRICT,
    CONSTRAINT chk_ac_status CHECK (status IN ('ACCRUED','WITHDRAWN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_ac_agent ON AgentCommissions(agent_user_id);
CREATE INDEX idx_ac_status ON AgentCommissions(status);
CREATE INDEX idx_ac_withdrawal ON AgentCommissions(withdrawal_id);

CREATE TABLE CommissionWithdrawals (
    withdrawal_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    agent_user_id              BIGINT UNSIGNED NOT NULL,
    amount                        DECIMAL(18,2) NOT NULL,
    status                          VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    requested_on                     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_by_user_id               BIGINT UNSIGNED NULL,
    processed_on                         DATETIME NULL,
    CONSTRAINT fk_cw_agent       FOREIGN KEY (agent_user_id)         REFERENCES Users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_cw_processed_by FOREIGN KEY (processed_by_user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_cw_status CHECK (status IN ('REQUESTED','APPROVED','PAID','REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_cw_agent ON CommissionWithdrawals(agent_user_id);

-- Added after CommissionWithdrawals exists (AgentCommissions is created first
-- since Purchases -> AgentCommissions ordering matters more than this link).
ALTER TABLE AgentCommissions
    ADD CONSTRAINT fk_ac_withdrawal FOREIGN KEY (withdrawal_id) REFERENCES CommissionWithdrawals(withdrawal_id) ON DELETE SET NULL;

-- =====================================================================
-- 7. AUDIT
-- =====================================================================

CREATE TABLE AuditLog (
    audit_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    actor_type        VARCHAR(20) NOT NULL,
    actor_id             BIGINT UNSIGNED NOT NULL,
    action                 VARCHAR(100) NOT NULL,
    entity                   VARCHAR(100) NOT NULL,
    entity_id                  BIGINT UNSIGNED NOT NULL,
    old_value                     JSON NULL,
    new_value                        JSON NULL,
    created_on                          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_audit_actor_type CHECK (actor_type IN ('USER','CLIENT','CHANNEL_SERVICE','GATEWAY_WEBHOOK'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_audit_entity ON AuditLog(entity, entity_id);
CREATE INDEX idx_audit_actor ON AuditLog(actor_type, actor_id);

-- =====================================================================
-- 8. PORTAL MENUS (Admin Portal navigation, role-scoped)
-- Independent of Permissions/RolePermissions above on purpose - menu
-- visibility is a UI/navigation concern (what a role sees in the sidebar),
-- not an authorization decision (what the API actually allows). The API
-- keeps enforcing real permissions via [Authorize(Policy = ...)] regardless
-- of what the portal shows or hides. Empty on a fresh install - rows get
-- added as each Admin Portal screen is actually built, not bulk-seeded
-- ahead of time.
-- =====================================================================

CREATE TABLE Menus (
    menu_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- NULL = top-level item. A top-level row is either a group header (url
    -- IS NULL, has children - e.g. "Access Control") or a direct link (url
    -- IS NOT NULL, no children - e.g. "Home"). Same shape one level down.
    parent_menu_id     BIGINT UNSIGNED NULL,
    label                VARCHAR(100) NOT NULL,
    icon                   VARCHAR(50) NULL COMMENT 'Font Awesome class, e.g. fa-home - portal renders it, no markup stored here',
    url                      VARCHAR(255) NULL,
    sort_order                 INT NOT NULL DEFAULT 0,
    is_active                    TINYINT(1) NOT NULL DEFAULT 1,
    created_by                     BIGINT UNSIGNED NULL,
    created_on                       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_menu_parent     FOREIGN KEY (parent_menu_id) REFERENCES Menus(menu_id) ON DELETE CASCADE,
    CONSTRAINT fk_menu_created_by FOREIGN KEY (created_by)     REFERENCES Users(user_id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_menu_parent ON Menus(parent_menu_id, sort_order);

-- Bare junction table, same shape as RolePermissions above - a row's mere
-- presence means that role can see that menu item; no separate can_access
-- flag, since "no row" already means "no access" (revoking = deleting).
CREATE TABLE RoleMenus (
    role_id  BIGINT UNSIGNED NOT NULL,
    menu_id  BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, menu_id),
    CONSTRAINT fk_rm_role FOREIGN KEY (role_id) REFERENCES Roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rm_menu FOREIGN KEY (menu_id) REFERENCES Menus(menu_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =====================================================================
-- SEED DATA — Roles, Permissions, RolePermissions
-- =====================================================================

INSERT INTO Roles (role_code, name, description) VALUES
    ('SA', 'SUPER_ADMIN',      'Manages entire system, creates Agent_admins, overall support. Cannot create clients/agents.'),
    ('AA', 'AGENT_ADMIN',      'Purchases on behalf of clients, manages agents/clients, underwriters, pricing.'),
    ('AG', 'AGENT',            'Registers/manages own clients, purchases on their behalf, earns commission.'),
    ('SP', 'SUPPORT_AGENT',    'Purchases/quotes on behalf of clients, views all records, no pricing/agent-creation/reports.'),
    ('CL', 'CLIENT',           'Views own purchase/policy records only.'),
    ('CS', 'CHANNEL_SERVICE',  'Service account for USSD/WhatsApp/Website-guest channels — scoped to quote/purchase/lookup.');

INSERT INTO Permissions (code, description) VALUES
    ('CREATE_ADMIN',        'Create Agent_admin accounts'),
    ('CREATE_AGENT',        'Create Agent accounts'),
    ('CREATE_CLIENT',       'Create Client records'),
    ('EDIT_CLIENT',         'Edit Client records'),
    ('MANAGE_UNDERWRITER',  'Add/edit Underwriters'),
    ('MANAGE_PRICING',      'Manage price mappings/formulas'),
    ('PURCHASE_ON_BEHALF',  'Purchase/quote insurance on behalf of a client'),
    ('VIEW_ALL_PURCHASES',  'View purchase records across all agents/clients'),
    ('DOWNLOAD_REPORTS',    'Download system reports'),
    ('WITHDRAW_COMMISSION', 'Request commission withdrawal'),
    ('MANAGE_CHANNELS',     'Register/list/activate/deactivate channel-service accounts and rotate their API keys'),
    ('MANAGE_MENUS',        'Add/edit Admin Portal menu items and control which roles can see them');

INSERT INTO RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM Roles r, Permissions p
WHERE
    -- SuperAdmin-only: channel accounts (USSD/WhatsApp/website-guest/future
    -- integrations) are system-level machine credentials, not something
    -- AgentAdmin's client/agent/pricing-management scope covers.
    -- Same system-level reasoning as MANAGE_CHANNELS above - portal
    -- navigation/RBAC configuration is a SuperAdmin-only concern, not part
    -- of AgentAdmin's client/agent/pricing-management scope.
    (r.role_code = 'SA' AND p.code IN ('CREATE_ADMIN','MANAGE_CHANNELS','MANAGE_MENUS'))
    OR (r.role_code = 'AA' AND p.code IN ('CREATE_AGENT','CREATE_CLIENT','EDIT_CLIENT','PURCHASE_ON_BEHALF','MANAGE_UNDERWRITER','MANAGE_PRICING','DOWNLOAD_REPORTS','VIEW_ALL_PURCHASES'))
    -- Agent deliberately does NOT hold EDIT_CLIENT: they can register new
    -- clients (CREATE_CLIENT) but cannot update or delete ANY client
    -- record, including their own - corrections/removals (e.g. a wrong
    -- KRA PIN) go through AgentAdmin or SupportAgent instead. Because
    -- ClientsController/VehiclesController's Update and Delete actions are
    -- gated purely by [Authorize(Policy = PermissionCodes.EditClient)]
    -- with no separate ownership check, removing this one permission is
    -- enough to block Agent from Update/Delete on both Clients and
    -- Vehicles - no C# changes needed.
    OR (r.role_code = 'AG' AND p.code IN ('CREATE_CLIENT','PURCHASE_ON_BEHALF','WITHDRAW_COMMISSION'))
    OR (r.role_code = 'SP' AND p.code IN ('CREATE_CLIENT','EDIT_CLIENT','PURCHASE_ON_BEHALF','VIEW_ALL_PURCHASES'))
    -- CHANNEL_SERVICE (USSD/WhatsApp/Website-guest) holds CREATE_CLIENT so
    -- a brand-new walk-in visitor on any of those channels can be
    -- registered inline during their first quote/purchase, with no prior
    -- signup/OTP step - same self-service shape the bima-dline-web site
    -- already had against the old backend. It still holds no other
    -- permission - PURCHASE_ON_BEHALF is deliberately NOT granted here,
    -- since PurchasesController.Create already lets ChannelService callers
    -- through without checking that permission at all (self-service, not
    -- "on behalf of" anyone else).
    OR (r.role_code = 'CS' AND p.code IN ('CREATE_CLIENT'));

-- =====================================================================
-- SEED DATA — Test channel-service accounts (USSD/WhatsApp/Website-guest)
-- DEV/TEST ONLY. api_key_hash is SHA-256 of a plaintext key documented
-- here (safe to publish since these aren't real credentials) - the
-- Postman collection uses these exact keys for the channel-login requests:
--   USSD:          ussd-test-key-2026
--   WHATSAPP:      whatsapp-test-key-2026
--   WEBSITE_GUEST: website-guest-test-key-2026 (bima-dline-web's server-side
--                  quoteApi.ts logs in with this - never sent to the
--                  browser, same as the old site's BIMA_API_EMAIL/PASSWORD.)
-- Before this ever runs anywhere but local dev, delete these three rows
-- and insert real ones with real, secret keys instead.
-- =====================================================================

INSERT INTO ChannelServiceAccounts (channel, api_key_hash, allowed_ip_range, role_id, is_active)
SELECT 'USSD', '87b18d082c70f90e982bcf21c082a431fe0fa42b69ed6fb350158ad7f38bb52', NULL, role_id, 1
FROM Roles WHERE role_code = 'CS';

INSERT INTO ChannelServiceAccounts (channel, api_key_hash, allowed_ip_range, role_id, is_active)
SELECT 'WHATSAPP', '770274fae9c95a70575c7041f6c3747852aaf2dd47ebb6abd667a7b87c42853', NULL, role_id, 1
FROM Roles WHERE role_code = 'CS';

INSERT INTO ChannelServiceAccounts (channel, api_key_hash, allowed_ip_range, role_id, is_active)
SELECT 'WEBSITE_GUEST', '1c230048d25826295aa2bc780fb29cb8cd5f67802e6ad56799b591d2cb1df375', NULL, role_id, 1
FROM Roles WHERE role_code = 'CS';

-- =====================================================================
-- SEED DATA — Test staff logins (SuperAdmin/AgentAdmin/Agent/SupportAgent)
-- DEV/TEST ONLY. Password for all four is: Test@1234
-- (password_hash values below are real BCrypt hashes of that password -
-- BCrypt.Net-Next's Verify() works against any standard bcrypt hash
-- regardless of what generated it, so these log in correctly against
-- BCryptPasswordHasher as-is.) Emails are fake @example.com addresses -
-- SCAPI delivery will fail for these in a real environment, which is fine
-- for exercising login/lockout; use a real email if you need to actually
-- receive the OTP for one of these accounts.
-- Before this ever runs anywhere but local dev, delete these four rows.
-- =====================================================================

INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash, status, must_change_password, created_on)
SELECT role_id, '90000001', 'Test SuperAdmin', 'test.superadmin@example.com', '254700000001',
       '$2b$11$JbAApQqc52TGfSkXA/G0iuYeK2jITAuVpitvA3GrIJKGOttRiNeoS', 'ACTIVE', 0, NOW()
FROM Roles WHERE role_code = 'SA';

INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash, status, must_change_password, created_on)
SELECT role_id, '90000002', 'Test AgentAdmin', 'test.agentadmin@example.com', '254700000002',
       '$2b$11$RNb0YNLlhXQPjOJOf/ODLesWDwubo1K1Mj2kwYlv2Nbt0r7a10eLS', 'ACTIVE', 0, NOW()
FROM Roles WHERE role_code = 'AA';

INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash, status, must_change_password, created_on)
SELECT role_id, '90000003', 'Test Agent', 'test.agent@example.com', '254700000003',
       '$2b$11$fZm62LJhPyFatTCa2YGZr.xZT/MuEjPE0uR3SJ.9C.OcDHVm97HSm', 'ACTIVE', 0, NOW()
FROM Roles WHERE role_code = 'AG';

INSERT INTO Users (role_id, id_no, full_name, email, phone, password_hash, status, must_change_password, created_on)
SELECT role_id, '90000004', 'Test SupportAgent', 'test.supportagent@example.com', '254700000004',
       '$2b$11$0cD/xQPnfocTNw2pnN5P4uwiu4UCnc8GuxqvPrskS4f30byU.vjRy', 'ACTIVE', 0, NOW()
FROM Roles WHERE role_code = 'SP';

-- =====================================================================
-- SEED DATA — Catalog (Products, Motor Categories, Vehicle Classes)
-- =====================================================================

INSERT INTO Products (name, code, pricing_method) VALUES
    ('Motor',                       'MOTOR',    'FIXED_MAPPING'),
    ('Medical Individual/Family',   'MED_IND',  'MANUAL_QUOTE'),
    ('Medical Corporate',           'MED_CORP', 'MANUAL_QUOTE'),
    ('Professional Indemnity',      'PI',       'MANUAL_QUOTE'),
    ('Travel Insurance',            'TRAVEL',   'MANUAL_QUOTE'),
    ('Domestic Insurance',          'DOMESTIC', 'MANUAL_QUOTE');

INSERT INTO MotorCategories (product_id, name)
SELECT product_id, 'TPO' FROM Products WHERE code = 'MOTOR'
UNION ALL
SELECT product_id, 'Comprehensive' FROM Products WHERE code = 'MOTOR';

-- policy_level_id values below match the legacy source data 1:1 by product
-- name (PSV-BUS/PSV-MATATU genuinely have none there, so they stay NULL).
INSERT INTO MotorVehicleClasses (name, requires_tonnage, policy_level_id) VALUES
    ('PSV-BUS', 0, NULL),
    ('PSV-MATATU', 0, NULL),
    ('PSV-TAXI / TUK TUK', 0, 5),
    ('PSV-PRIVATE HIRE/Uber', 0, 1),
    ('PRIVATE', 0, 3),
    ('MOTOR COMMERCIAL:OWN GOODS', 1, 2),
    ('MOTOR COMMERCIAL:INSTITUTION', 1, 2),
    ('MOTOR COMMERCIAL:Prime Mover', 1, 2),
    ('MOTOR COMMERCIAL:Trailer', 1, 2),
    ('MOTOR COMMERCIAL:Tankers & Specified Trailer', 1, 2),
    ('MOTORCYCLE:PRIVATE', 0, 4),
    ('MOTORCYCLE:PSV', 0, 6),
    ('MOTOR COMMERCIAL:GENERAL', 1, 2),
    ('MOTOR COMMERCIAL:TRACTOR', 1, 2);

INSERT INTO Periods (name, duration_days) VALUES
    ('1 Week', 7),
    ('2 Weeks', 14),
    ('1 Month', 30),
    ('6 Months', 182),
    ('1 Year', 365);
