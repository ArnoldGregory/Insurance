#!/bin/bash
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform 2>/dev/null <<'SQL'
SELECT mi.menu_item_id, mi.name, mi.icon, mi.route, mi.sort_order, mi.is_active, r.role_code
FROM MenuItems mi
LEFT JOIN MenuItemRoleAssignments mra ON mra.menu_item_id = mi.menu_item_id
LEFT JOIN Roles r ON r.role_id = mra.role_id
ORDER BY mi.sort_order, r.role_code;
SQL