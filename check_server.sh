#!/bin/bash
echo "=== Server resources ==="
free -h
df -h / | tail -1
uptime
echo ""
echo "=== Top processes ==="
ps aux --sort=-%cpu | head -10
echo ""
echo "=== MySQL processlist ==="
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -e "SHOW FULL PROCESSLIST;" 2>/dev/null
echo ""
echo "=== MySQL variable timeouts ==="
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -e "SHOW VARIABLES LIKE '%timeout%';" 2>/dev/null | grep -i "connect\|wait\|read\|interactive"
echo ""
echo "=== InnoDB status (lock section) ==="
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -e "SHOW ENGINE INNODB STATUS\G" 2>/dev/null | grep -A30 "LATEST DETECTED DEADLOCK" | head -40