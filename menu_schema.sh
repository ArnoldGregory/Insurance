#!/bin/bash
echo '=== tables like menu ==='
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "SHOW TABLES LIKE 'menu%'" 2>/dev/null
echo '=== tables like role ==='
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "SHOW TABLES LIKE '%role%'" 2>/dev/null
echo '=== count menu rows ==='
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "SELECT COUNT(*) FROM MenuItems" 2>/dev/null