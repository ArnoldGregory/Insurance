-- Support Agents screen: /Staff/SupportAgents, granted to SA + AA.
-- One-time migration - guarded so it can be re-run without duplicating.
USE insurance_platform;

SET @actor = NULL;
SELECT u.user_id INTO @actor
FROM Users u
JOIN Roles r ON r.role_id = u.role_id
WHERE r.role_code = 'SA'
ORDER BY u.user_id
LIMIT 1;

SELECT @actor AS resolved_superadmin_user_id,
       IF(@actor IS NULL, 'STOP: no SuperAdmin user found.', 'OK - continuing.') AS status;

-- Staff group = menu_id 32 (already seeded).
SET @staff_id = 32;

-- Guarded create (no-op if it already exists) - plain INSERT keeps this
-- re-runnable without the duplicate rows a raw CALL of usp_Menu_Create
-- would produce.
INSERT INTO Menus (parent_menu_id, label, icon, url, sort_order, is_active, created_by, created_on)
SELECT @staff_id, 'Support Agents', 'fa-headset', '/Staff/SupportAgents', 30, 1, @actor, NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM Menus WHERE parent_menu_id = @staff_id AND label = 'Support Agents'
);

INSERT INTO AuditLog (actor_type, actor_id, action, entity, entity_id, old_value, new_value, created_on)
SELECT 'USER', @actor, 'CREATE', 'Menus', m.menu_id, NULL,
       JSON_OBJECT('parent_menu_id', m.parent_menu_id, 'label', m.label, 'icon', m.icon, 'url', m.url, 'sort_order', m.sort_order),
       NOW()
FROM Menus m
WHERE m.parent_menu_id = @staff_id AND m.label = 'Support Agents'
  AND NOT EXISTS (
      SELECT 1 FROM AuditLog a
      WHERE a.action = 'CREATE' AND a.entity = 'Menus' AND a.entity_id = m.menu_id
  );

SET @menu_id = NULL;
SELECT menu_id INTO @menu_id FROM Menus WHERE parent_menu_id = @staff_id AND label = 'Support Agents' LIMIT 1;

-- Grants (INSERT IGNORE + audited, reuse the canonical proc for the audit shape).
CALL usp_RoleMenu_SetAccess('SA', @menu_id, 1, @actor, @code, @msg);
CALL usp_RoleMenu_SetAccess('AA', @menu_id, 1, @actor, @code, @msg);

-- Verify.
SELECT m.menu_id, m.label, m.url, m.sort_order
FROM Menus m
WHERE m.parent_menu_id = @staff_id
ORDER BY m.sort_order;

SELECT m.label, r.role_code
FROM RoleMenus rm
JOIN Menus m ON m.menu_id = rm.menu_id
JOIN Roles r ON r.role_id = rm.role_id
WHERE m.parent_menu_id = @staff_id
ORDER BY m.sort_order, r.role_code;