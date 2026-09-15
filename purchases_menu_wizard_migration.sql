-- =====================================================================
-- Migration: turn the existing top-level "Purchases" menu item into a
-- group with 3 children - Browse Purchases (existing list), TPO (new
-- purchase wizard), Comprehensive (placeholder).
-- -----------------------------------------------------------------------
-- Safe to run once. The UPDATE at the top clears Purchases' own url back
-- to NULL directly (usp_Menu_Update can't do this - it COALESCEs, so a
-- NULL argument leaves the existing value alone rather than clearing it;
-- see that proc's own doc comment in Insurance_API_StoredProcs_Menus.sql).
-- Everything after that goes through the normal procs. Re-running the
-- child-INSERT half would create duplicates (same lesson as
-- seed_menus_full_tree.sql) - only run this once.
-- =====================================================================

USE insurance_platform;

-- Resolve a real actor for AuditLog.actor_id (NOT NULL - see the
-- seed_menus_full_tree.sql fix for why this step exists).
SELECT u.user_id INTO @actor
FROM Users u
JOIN Roles r ON r.role_id = u.role_id
WHERE r.role_code = 'SA'
ORDER BY u.user_id
LIMIT 1;

SELECT @actor AS resolved_superadmin_user_id,
       IF(@actor IS NULL, 'STOP: no SuperAdmin user found - create one before continuing.', 'OK - continuing with this actor.') AS status;

-- 1. Clear Purchases' own url - once it has children, MenuViewComponent
-- renders it as a collapsible group header, not a direct link (its url is
-- ignored if non-null, but NULL is the honest/consistent value here).
UPDATE Menus SET url = NULL WHERE label = 'Purchases' AND parent_menu_id IS NULL;

SELECT menu_id INTO @purchases_id FROM Menus WHERE label = 'Purchases' AND parent_menu_id IS NULL LIMIT 1;

SELECT @purchases_id AS resolved_purchases_menu_id,
       IF(@purchases_id IS NULL, 'STOP: no top-level "Purchases" menu item found - run seed_menus_full_tree.sql first.', 'OK - continuing.') AS status;

-- 2. Add the 3 children.
SET @code = NULL; SET @msg = NULL; SET @id = NULL;

CALL usp_Menu_Create(@purchases_id, 'Browse Purchases', NULL, '/Purchases/Index', 10, @actor, @code, @msg, @id);
SET @m_browse = @id;

CALL usp_Menu_Create(@purchases_id, 'TPO', NULL, '/PurchaseWizard/Step1', 20, @actor, @code, @msg, @id);
SET @m_tpo = @id;

CALL usp_Menu_Create(@purchases_id, 'Comprehensive', NULL, '/PurchaseWizard/Comprehensive', 30, @actor, @code, @msg, @id);
SET @m_comp = @id;

-- 3. Role-access grants.
-- Browse Purchases: SA, AA, AG, SP (matches PurchasesController.GetList's
-- own [Authorize(Roles=SA,AA,AG,SP)] - everyone who could see the old
-- direct link can still see the browse child).
CALL usp_RoleMenu_SetAccess('SA', @m_browse, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_browse, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_browse, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_browse, 1, @actor, @code, @msg);

-- TPO / Comprehensive: AA, AG, SP only - matches PURCHASE_ON_BEHALF (SA
-- lacks it; PurchasesController.Create would 403 a SuperAdmin who tried).
CALL usp_RoleMenu_SetAccess('AA', @m_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_tpo, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @m_comp, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @m_comp, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @m_comp, 1, @actor, @code, @msg);

-- The "Purchases" group header itself now needs to be granted to every
-- role that can see at least one child (it already was granted to SA/AA/
-- AG/SP from the original seed, which covers all of the above - nothing
-- new needed here since usp_RoleMenu_SetAccess's grant path is
-- idempotent/INSERT IGNORE, but shown for completeness/safety):
CALL usp_RoleMenu_SetAccess('SA', @purchases_id, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @purchases_id, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AG', @purchases_id, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('SP', @purchases_id, 1, @actor, @code, @msg);

-- Verification.
SELECT m.menu_id, m.parent_menu_id, m.label, m.url, m.sort_order,
       GROUP_CONCAT(r.role_code ORDER BY r.role_code SEPARATOR ',') AS granted_roles
FROM Menus m
LEFT JOIN RoleMenus rm ON rm.menu_id = m.menu_id
LEFT JOIN Roles r ON r.role_id = rm.role_id
WHERE m.menu_id = @purchases_id OR m.parent_menu_id = @purchases_id
GROUP BY m.menu_id, m.parent_menu_id, m.label, m.url, m.sort_order
ORDER BY m.parent_menu_id IS NOT NULL, m.sort_order;
