-- =====================================================================
-- Seed: Admin Portal menu tree + role-access grants (Menus / RoleMenus)
-- -----------------------------------------------------------------------
-- Not destructive - only CALLs usp_Menu_Create / usp_RoleMenu_SetAccess,
-- which are plain INSERTs (usp_RoleMenu_SetAccess's grant path is
-- INSERT IGNORE, so re-running this script is harmless/idempotent for the
-- role-access half; re-running the usp_Menu_Create half WOULD create
-- duplicate menu rows, since Menus has no unique constraint on label - so
-- only run the "CREATE MENUS" section once).
--
-- Requires Insurance_API_StoredProcs_Menus.sql to already be loaded.
--
-- This derives every grant directly from the actual permission model
-- already live in Insurance_API_Schema.sql's RolePermissions seed and the
-- real [Authorize] attributes on each controller - see the comment above
-- each menu item for exactly which check it matches. Menu visibility only
-- controls what shows in the sidebar (Menus/RoleMenus); it does NOT change
-- what the API itself allows - that's still enforced by each endpoint's
-- own [Authorize(Policy=...)]/[Authorize(Roles=...)] regardless of what
-- this script grants.
--
-- Several URLs below (e.g. /Purchases/Index, /Clients/Index) point at
-- AdminPortal MVC screens that don't exist yet as of this script - they'll
-- 404 until each one is built in a later phase. That's expected: the menu
-- tree/role-access model is being seeded in full now so it can be
-- reviewed and adjusted (via the new Menu Management screen itself) ahead
-- of building each screen, rather than growing the tree piecemeal.
-- =====================================================================

USE insurance_platform;

SET @code = NULL; SET @msg = NULL; SET @id = NULL;

-- Every usp_Menu_Create/usp_RoleMenu_SetAccess call writes an AuditLog row,
-- and AuditLog.actor_id is NOT NULL (unlike Menus.created_by, which is
-- nullable) - so this can't just pass NULL for "no particular actor" the
-- way the very first draft of this script tried. Instead it resolves a
-- real SuperAdmin's user_id once here and reuses it as @actor for every
-- call below, so the audit trail correctly shows "the SuperAdmin who ran
-- this seed script" rather than a placeholder.
SELECT u.user_id INTO @actor
FROM Users u
JOIN Roles r ON r.role_id = u.role_id
WHERE r.role_code = 'SA'
ORDER BY u.user_id
LIMIT 1;

-- Sanity-check before running 63 CALLs: if @actor came back NULL, no
-- SuperAdmin user exists yet in Users - STOP here, create one first (e.g.
-- via StaffController's own bootstrap path or directly in the database),
-- then re-run this whole script. Every CALL below would otherwise fail
-- one-by-one with the same "Column 'actor_id' cannot be null" error this
-- script was just fixed to avoid.
SELECT @actor AS resolved_superadmin_user_id,
       IF(@actor IS NULL, 'STOP: no SuperAdmin user found - create one before continuing.', 'OK - continuing with this actor.') AS status;

-- ---------------------------------------------------------------------
-- 10. Dashboard - /Home/Index - open to every portal role (no permission
-- gate on the dashboard itself).
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Dashboard', 'fa-tachometer-alt', '/Home/Index', 10, @actor, @code, @msg, @id);
SET @m_dashboard = @id;

-- ---------------------------------------------------------------------
-- 20. Quote Requests - /QuoteRequests/Index - matches QuoteRequestsController's
-- BackofficeRoles = SA,AA,SP (assign/expire/create-offers).
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Quote Requests', 'fa-clipboard-list', '/QuoteRequests/Index', 20, @actor, @code, @msg, @id);
SET @m_quotereq = @id;

-- ---------------------------------------------------------------------
-- 30. Purchases - /Purchases/Index - pending-payment is [Authorize(Roles=
-- SA,AA,AG,SP)]; status-change is narrower (SA,AA,SP) but that's a
-- button-level check inside the screen, not a menu-level one.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Purchases', 'fa-shopping-cart', '/Purchases/Index', 30, @actor, @code, @msg, @id);
SET @m_purchases = @id;

-- ---------------------------------------------------------------------
-- 40. Payments - /Payments/Index - status-update is [Authorize(Roles=
-- CS,SA,AA,SP)] (CS is machine-to-machine, not a portal role).
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Payments', 'fa-credit-card', '/Payments/Index', 40, @actor, @code, @msg, @id);
SET @m_payments = @id;

-- ---------------------------------------------------------------------
-- 50. Clients - /Clients/Index - GetList/GetById are plain [Authorize]
-- (viewable by every portal role); CREATE_CLIENT is held by AA/AG/SP
-- (not SA), EDIT_CLIENT by AA/SP only - those are per-button checks
-- inside the screen.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Clients', 'fa-users', '/Clients/Index', 50, @actor, @code, @msg, @id);
SET @m_clients = @id;

-- ---------------------------------------------------------------------
-- 60. Underwriters - /Underwriters/Index - GetById/GetList are
-- [Authorize(Roles=SA,AA,SP)]; MANAGE_UNDERWRITER (create/edit) is AA-only.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Underwriters', 'fa-shield-alt', '/Underwriters/Index', 60, @actor, @code, @msg, @id);
SET @m_underwriters = @id;

-- ---------------------------------------------------------------------
-- 70. Pricing (group) - MANAGE_PRICING is AA-only for writes; reads are
-- broader [Authorize]. Viewable by SA/AA/SP.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Pricing', 'fa-tags', NULL, 70, @actor, @code, @msg, @id);
SET @m_pricing = @id;
CALL usp_Menu_Create(@m_pricing, 'TPO Price Mapping', 'fa-percentage', '/Pricing/Tpo', 10, @actor, @code, @msg, @id);
SET @m_pricing_tpo = @id;
CALL usp_Menu_Create(@m_pricing, 'Comprehensive Formulas', 'fa-calculator', '/Pricing/Comprehensive', 20, @actor, @code, @msg, @id);
SET @m_pricing_comp = @id;

-- ---------------------------------------------------------------------
-- 80. Products - /Products/Index - reference data (motor categories,
-- vehicle classes, periods, policy levels), read-only, no write endpoints
-- exist. Viewable by SA/AA/SP for context when configuring Pricing/
-- Underwriters.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Products', 'fa-car', '/Products/Index', 80, @actor, @code, @msg, @id);
SET @m_products = @id;

-- ---------------------------------------------------------------------
-- 90. Commissions (group) - two different screens depending on role:
-- AgentCommissionsController's BackofficeRoles = AA,SP (manage rates,
-- approve withdrawals); Agent (AG) only sees their own via /me, /me/
-- balance, /me/withdrawals (WITHDRAW_COMMISSION is AG-only).
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Commissions', 'fa-hand-holding-usd', NULL, 90, @actor, @code, @msg, @id);
SET @m_commissions = @id;
CALL usp_Menu_Create(@m_commissions, 'Manage Commissions', 'fa-money-check-alt', '/Commissions/Manage', 10, @actor, @code, @msg, @id);
SET @m_commissions_manage = @id;
CALL usp_Menu_Create(@m_commissions, 'My Commissions', 'fa-wallet', '/Commissions/Mine', 20, @actor, @code, @msg, @id);
SET @m_commissions_mine = @id;

-- ---------------------------------------------------------------------
-- 100. Staff (group) - StaffController: CREATE_ADMIN is SA-only (create
-- AgentAdmins), CREATE_AGENT is AA-only (create Agents).
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Staff', 'fa-user-tie', NULL, 100, @actor, @code, @msg, @id);
SET @m_staff = @id;
CALL usp_Menu_Create(@m_staff, 'Agent Admins', 'fa-user-shield', '/Staff/AgentAdmins', 10, @actor, @code, @msg, @id);
SET @m_staff_admins = @id;
CALL usp_Menu_Create(@m_staff, 'Agents', 'fa-user-plus', '/Staff/Agents', 20, @actor, @code, @msg, @id);
SET @m_staff_agents = @id;
CALL usp_Menu_Create(@m_staff, 'Support Agents', 'fa-headset', '/Staff/SupportAgents', 30, @actor, @code, @msg, @id);
SET @m_staff_support = @id;

-- ---------------------------------------------------------------------
-- 110. Channel Accounts - /ChannelAccounts/Index - MANAGE_CHANNELS,
-- SA-only.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Channel Accounts', 'fa-plug', '/ChannelAccounts/Index', 110, @actor, @code, @msg, @id);
SET @m_channels = @id;

-- ---------------------------------------------------------------------
-- 120. Menu Management - /Menus/Index - MANAGE_MENUS, SA-only. The
-- screen that edits everything this script just seeded.
-- ---------------------------------------------------------------------
CALL usp_Menu_Create(NULL, 'Menu Management', 'fa-sitemap', '/Menus/Index', 120, @actor, @code, @msg, @id);
SET @m_menumgmt = @id;


-- =====================================================================
-- ROLE-ACCESS GRANTS
-- Reminder from usp_RoleMenu_GetForRole: a child only shows for a role if
-- BOTH the child AND its parent are granted to that role - so every group
-- header below is granted to every role that has at least one visible
-- child.
-- =====================================================================

-- Dashboard: SA, AA, AG, SP
CALL usp_RoleMenu_SetAccess('SA', @m_dashboard, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_dashboard, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_dashboard, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_dashboard, 1, @actor, @code, @msg);

-- Quote Requests: SA, AA, SP
CALL usp_RoleMenu_SetAccess('SA', @m_quotereq, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_quotereq, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_quotereq, 1, @actor, @code, @msg);

-- Purchases: SA, AA, AG, SP
CALL usp_RoleMenu_SetAccess('SA', @m_purchases, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_purchases, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_purchases, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_purchases, 1, @actor, @code, @msg);

-- Payments: SA, AA, SP
CALL usp_RoleMenu_SetAccess('SA', @m_payments, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_payments, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_payments, 1, @actor, @code, @msg);

-- Clients: SA, AA, AG, SP
CALL usp_RoleMenu_SetAccess('SA', @m_clients, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_clients, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_clients, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_clients, 1, @actor, @code, @msg);

-- Underwriters: SA, AA, SP
CALL usp_RoleMenu_SetAccess('SA', @m_underwriters, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_underwriters, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_underwriters, 1, @actor, @code, @msg);

-- Pricing (group + both children): SA, AA, SP
CALL usp_RoleMenu_SetAccess('SA', @m_pricing, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_pricing, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_pricing, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SA', @m_pricing_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_pricing_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_pricing_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SA', @m_pricing_comp, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_pricing_comp, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_pricing_comp, 1, @actor, @code, @msg);

-- Products: SA, AA, SP
CALL usp_RoleMenu_SetAccess('SA', @m_products, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_products, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_products, 1, @actor, @code, @msg);

-- Commissions (group): AA, SP, AG (each sees a different child, see below)
CALL usp_RoleMenu_SetAccess('AA', @m_commissions, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_commissions, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_commissions, 1, @actor, @code, @msg);
-- Manage Commissions child: AA, SP only
CALL usp_RoleMenu_SetAccess('AA', @m_commissions_manage, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_commissions_manage, 1, @actor, @code, @msg);
-- My Commissions child: AG only
CALL usp_RoleMenu_SetAccess('AG', @m_commissions_mine, 1, @actor, @code, @msg);

-- Staff (group): SA, AA (each sees a different child, see below)
CALL usp_RoleMenu_SetAccess('SA', @m_staff, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_staff, 1, @actor, @code, @msg);
-- Agent Admins child: SA only
CALL usp_RoleMenu_SetAccess('SA', @m_staff_admins, 1, @actor, @code, @msg);
-- Agents child: AA only
CALL usp_RoleMenu_SetAccess('AA', @m_staff_agents, 1, @actor, @code, @msg);
-- Support Agents child: SA + AA (StaffController.SupportAgents is [Authorize(Roles="SA,AA")])
CALL usp_RoleMenu_SetAccess('SA', @m_staff_support, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_staff_support, 1, @actor, @code, @msg);

-- Channel Accounts: SA only
CALL usp_RoleMenu_SetAccess('SA', @m_channels, 1, @actor, @code, @msg);

-- Menu Management: SA only
CALL usp_RoleMenu_SetAccess('SA', @m_menumgmt, 1, @actor, @code, @msg);


-- =====================================================================
-- Verification - review the full tree and every grant before trusting
-- the sidebar output.
-- =====================================================================
SELECT m.menu_id, m.parent_menu_id, m.label, m.icon, m.url, m.sort_order,
       GROUP_CONCAT(r.role_code ORDER BY r.role_code SEPARATOR ',') AS granted_roles
FROM Menus m
LEFT JOIN RoleMenus rm ON rm.menu_id = m.menu_id
LEFT JOIN Roles r ON r.role_id = rm.role_id
GROUP BY m.menu_id, m.parent_menu_id, m.label, m.icon, m.url, m.sort_order
ORDER BY COALESCE(m.parent_menu_id, m.menu_id), m.parent_menu_id IS NOT NULL, m.sort_order;
