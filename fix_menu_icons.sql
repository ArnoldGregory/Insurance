-- =====================================================================
-- Fix: sidebar menu icons
-- -----------------------------------------------------------------------
-- Two problems found after seed_menus_full_tree.sql was already run
-- against a live database:
--
-- 1. Five top-level items were seeded with FontAwesome 6 icon class
--    names (fa-gauge-high, fa-file-circle-question, fa-cart-shopping,
--    fa-building-shield, fa-sack-dollar). The AdminPortal only vendors
--    FontAwesome 5.15.3 (see _Layout.cshtml's <link> to
--    fontawesome-5.15.3/css/all.min.css), and that vendored file is a
--    trimmed subset that doesn't define those FA6-only classes - so
--    those five sidebar rows rendered with no icon glyph at all
--    (the <i class="fa fa-gauge-high"> tag renders, it just has no
--    matching CSS rule to draw anything). Confirmed each replacement
--    class below actually exists in the vendored all.min.css before
--    picking it.
--
-- 2. Six sub-menu items (the two Pricing children, two Commissions
--    children, two Staff children) were seeded with icon = NULL on
--    purpose at the time (sub-items weren't rendering icons yet).
--    Default.cshtml has since been updated to render an icon for
--    sub-menu items too, so these now need a real icon value to show
--    anything.
--
-- This is a plain UPDATE (not CALL usp_Menu_Update) because it's a
-- one-time data fix across many rows in one pass - usp_Menu_Update
-- writes an AuditLog row per call (one call per menu item), which
-- isn't warranted for a same-day icon-name typo fix. Safe to re-run
-- (idempotent - just re-sets the same values).
--
-- Run this once against the live database. Also see
-- seed_menus_full_tree.sql, which has been updated with these same
-- icon values so a *fresh* environment seeded from scratch doesn't
-- need this fix at all.
-- =====================================================================

USE insurance_platform;

-- ---- Top-level items: FA6-only class -> real FA5.15.3 equivalent ----
UPDATE Menus SET icon = 'fa-tachometer-alt' WHERE label = 'Dashboard' AND parent_menu_id IS NULL;
UPDATE Menus SET icon = 'fa-clipboard-list' WHERE label = 'Quote Requests' AND parent_menu_id IS NULL;
UPDATE Menus SET icon = 'fa-shopping-cart'  WHERE label = 'Purchases' AND parent_menu_id IS NULL;
UPDATE Menus SET icon = 'fa-shield-alt'     WHERE label = 'Underwriters' AND parent_menu_id IS NULL;
UPDATE Menus SET icon = 'fa-hand-holding-usd' WHERE label = 'Commissions' AND parent_menu_id IS NULL;

-- ---- Sub-menu items: previously NULL -> a real icon ----
-- Pricing's children
UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Pricing'
SET m.icon = 'fa-percentage'
WHERE m.label = 'TPO Price Mapping';

UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Pricing'
SET m.icon = 'fa-calculator'
WHERE m.label = 'Comprehensive Formulas';

-- Commissions's children
UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Commissions'
SET m.icon = 'fa-money-check-alt'
WHERE m.label = 'Manage Commissions';

UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Commissions'
SET m.icon = 'fa-wallet'
WHERE m.label = 'My Commissions';

-- Staff's children
UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Staff'
SET m.icon = 'fa-user-shield'
WHERE m.label = 'Agent Admins';

UPDATE Menus m
JOIN Menus p ON p.menu_id = m.parent_menu_id AND p.label = 'Staff'
SET m.icon = 'fa-user-plus'
WHERE m.label = 'Agents';

-- ---------------------------------------------------------------------
-- Verification - every row should now show a non-NULL icon.
-- ---------------------------------------------------------------------
SELECT m.menu_id, m.parent_menu_id, m.label, m.icon, m.url, m.sort_order
FROM Menus m
ORDER BY COALESCE(m.parent_menu_id, m.menu_id), m.parent_menu_id IS NOT NULL, m.sort_order;
