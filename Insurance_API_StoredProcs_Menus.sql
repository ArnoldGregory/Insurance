-- =====================================================================
-- Insurance Platform — Stored Procedures: PORTAL MENUS (v1)
-- MySQL 8.0+ / follows Insurance_API_StoredProc_Conventions.md
-- Covers: Admin Portal navigation - menu CRUD, and role-scoped grants
-- (RoleMenus) driving what each role's sidebar actually shows. Independent
-- of Permissions/RolePermissions - see Menus/RoleMenus' comments in
-- Insurance_API_Schema.sql for why menu visibility and API authorization
-- are deliberately two separate systems.
-- =====================================================================

USE insurance_platform;

DELIMITER $$

-- =====================================================================
-- MENUS
-- =====================================================================

DROP PROCEDURE IF EXISTS usp_Menu_Create $$
CREATE PROCEDURE usp_Menu_Create (
    IN  p_parent_menu_id BIGINT UNSIGNED,
    IN  p_label          VARCHAR(100),
    IN  p_icon           VARCHAR(50),
    IN  p_url            VARCHAR(255),
    IN  p_sort_order     INT,
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500),
    OUT o_menu_id        BIGINT UNSIGNED
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_label IS NULL OR TRIM(p_label) = '' THEN
        SET o_result_code = 1;
        SET o_result_message = 'label is required.';
        LEAVE proc_label;
    END IF;

    IF p_parent_menu_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Menus WHERE menu_id = p_parent_menu_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'parent_menu_id not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    INSERT INTO Menus (parent_menu_id, label, icon, url, sort_order, is_active, created_by, created_on)
    VALUES (p_parent_menu_id, p_label, p_icon, p_url, COALESCE(p_sort_order, 0), 1, p_actor_id, NOW());

    SET o_menu_id = LAST_INSERT_ID();

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'CREATE', 'Menus', o_menu_id, NULL,
            JSON_OBJECT('parent_menu_id', p_parent_menu_id, 'label', p_label, 'icon', p_icon, 'url', p_url, 'sort_order', p_sort_order),
            NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Menu_Update
-- Partial update, same COALESCE-over-NULL trade-off as usp_Underwriter_Update:
-- passing NULL for a field leaves it unchanged, which also means there's
-- no way to explicitly clear icon/url back to NULL through this proc alone
-- (delete-and-recreate, or a future dedicated "clear" proc, if that's ever
-- needed) - accepted here for consistency with the rest of this codebase
-- rather than inventing a different partial-update convention just for
-- Menus.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Menu_Update $$
CREATE PROCEDURE usp_Menu_Update (
    IN  p_menu_id        BIGINT UNSIGNED,
    IN  p_label          VARCHAR(100),
    IN  p_icon           VARCHAR(50),
    IN  p_url            VARCHAR(255),
    IN  p_sort_order     INT,
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_old JSON;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF p_menu_id IS NULL THEN
        SET o_result_code = 1;
        SET o_result_message = 'menu_id is required.';
        LEAVE proc_label;
    END IF;

    SELECT JSON_OBJECT('label', label, 'icon', icon, 'url', url, 'sort_order', sort_order)
    INTO v_old FROM Menus WHERE menu_id = p_menu_id;

    IF v_old IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Menu not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    UPDATE Menus
    SET label      = COALESCE(p_label, label),
        icon       = COALESCE(p_icon, icon),
        url        = COALESCE(p_url, url),
        sort_order = COALESCE(p_sort_order, sort_order)
    WHERE menu_id = p_menu_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'Menus', p_menu_id,
            v_old, JSON_OBJECT('label', p_label, 'icon', p_icon, 'url', p_url, 'sort_order', p_sort_order), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DROP PROCEDURE IF EXISTS usp_Menu_SetActiveStatus $$
CREATE PROCEDURE usp_Menu_SetActiveStatus (
    IN  p_menu_id        BIGINT UNSIGNED,
    IN  p_is_active      TINYINT(1),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    IF NOT EXISTS (SELECT 1 FROM Menus WHERE menu_id = p_menu_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Menu not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- Deactivating a top-level item does NOT cascade-deactivate its
    -- children here - usp_RoleMenu_GetForRole is what actually hides a
    -- child whose parent is inactive (see its WHERE clause), so the
    -- children's own is_active flags stay meaningful independently (e.g.
    -- reactivating the parent later brings back exactly the children that
    -- were still individually active).
    UPDATE Menus SET is_active = p_is_active WHERE menu_id = p_menu_id;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, 'UPDATE', 'Menus', p_menu_id, NULL, JSON_OBJECT('is_active', p_is_active), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_Menu_GetList
-- Admin's flat list for building the menu editor UI (parent picker,
-- reordering, etc.) - includes inactive rows, unlike usp_RoleMenu_GetForRole
-- below. Self-joins to Menus once to sort each item under its top-level
-- ancestor's own sort_order, parent row before its children, children then
-- ordered by their own sort_order - a 2-level list, group by group.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_Menu_GetList $$
CREATE PROCEDURE usp_Menu_GetList (
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    SELECT m.menu_id, m.parent_menu_id, m.label, m.icon, m.url, m.sort_order, m.is_active, m.created_on
    FROM Menus m
    LEFT JOIN Menus p ON p.menu_id = m.parent_menu_id
    ORDER BY COALESCE(p.sort_order, m.sort_order),
             COALESCE(p.menu_id, m.menu_id),
             (m.parent_menu_id IS NOT NULL),
             m.sort_order;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- =====================================================================
-- ROLE MENU ACCESS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usp_RoleMenu_SetAccess
-- Grants (p_can_access = 1) or revokes (p_can_access = 0) one role's
-- access to one menu item. INSERT IGNORE on grant makes granting an
-- already-granted item a harmless no-op rather than a duplicate-key error
-- (same idempotent-toggle shape as the rest of this codebase's "Set"
-- procs).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_RoleMenu_SetAccess $$
CREATE PROCEDURE usp_RoleMenu_SetAccess (
    IN  p_role_code      VARCHAR(20),
    IN  p_menu_id        BIGINT UNSIGNED,
    IN  p_can_access     TINYINT(1),
    IN  p_actor_id       BIGINT UNSIGNED,
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    DECLARE v_role_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;
    END;

    SELECT role_id INTO v_role_id FROM Roles WHERE role_code = p_role_code;

    IF v_role_id IS NULL THEN
        SET o_result_code = 2;
        SET o_result_message = 'Role not found.';
        LEAVE proc_label;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Menus WHERE menu_id = p_menu_id) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Menu not found.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    IF p_can_access = 1 THEN
        INSERT IGNORE INTO RoleMenus (role_id, menu_id) VALUES (v_role_id, p_menu_id);
    ELSE
        DELETE FROM RoleMenus WHERE role_id = v_role_id AND menu_id = p_menu_id;
    END IF;

    INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
    VALUES ('USER', p_actor_id, IF(p_can_access = 1, 'GRANT', 'REVOKE'), 'RoleMenus', p_menu_id,
            NULL, JSON_OBJECT('role_code', p_role_code, 'menu_id', p_menu_id, 'can_access', p_can_access), NOW());

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

-- ---------------------------------------------------------------------
-- usp_RoleMenu_GetForRole
-- The Admin Portal calls this exactly once after login (p_role_code taken
-- straight from the caller's own JWT role claim - see BaseApiController.
-- CurrentRoleCode) to build the sidebar. Same proc also backs the admin
-- "which menus can role X see" config screen by passing a different
-- role_code. A child row only comes back if BOTH it and its parent are
-- active AND granted to this role - see the WHERE clause comment.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS usp_RoleMenu_GetForRole $$
CREATE PROCEDURE usp_RoleMenu_GetForRole (
    IN  p_role_code      VARCHAR(20),
    OUT o_result_code    INT,
    OUT o_result_message VARCHAR(500)
)
proc_label: BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_code = p_role_code) THEN
        SET o_result_code = 2;
        SET o_result_message = 'Role not found.';
        LEAVE proc_label;
    END IF;

    SELECT m.menu_id, m.parent_menu_id, m.label, m.icon, m.url, m.sort_order
    FROM Menus m
    JOIN RoleMenus rm ON rm.menu_id = m.menu_id
    JOIN Roles r ON r.role_id = rm.role_id
    LEFT JOIN Menus p ON p.menu_id = m.parent_menu_id
    WHERE r.role_code = p_role_code
      AND m.is_active = 1
      -- A group header hidden from this role hides everything under it,
      -- and a deactivated parent hides its children even if they're
      -- individually still active/granted - a child only ever shows if
      -- its own parent is both active AND separately granted to the same
      -- role.
      AND (m.parent_menu_id IS NULL OR (
            p.is_active = 1
            AND EXISTS (SELECT 1 FROM RoleMenus rm2 WHERE rm2.role_id = rm.role_id AND rm2.menu_id = m.parent_menu_id)
          ))
    ORDER BY COALESCE(p.sort_order, m.sort_order),
             COALESCE(p.menu_id, m.menu_id),
             (m.parent_menu_id IS NOT NULL),
             m.sort_order;

    SET o_result_code = 0;
    SET o_result_message = 'Success';
END $$

DELIMITER ;
