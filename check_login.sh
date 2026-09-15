#!/bin/bash
echo "=== Login proc name check ==="
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "SHOW CREATE PROCEDURE usp_User_Login" 2>/dev/null | head -3
echo ""
echo "=== DB proc speed test ==="
time (mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "CALL usp_User_Login('90000002','wrongpass',@a,@b); SELECT CONCAT(@a,'|',LEFT(@b,60));" 2>/dev/null)
echo ""
echo "=== API login speed test ==="
curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' -X POST https://insuranceapi.riziki.app/api/auth/login -H 'Content-Type: application/json' -H 'x-channel: BACKOFFICE' -d '{"idNo":"90000002","password":"wrongpass"}'
echo ""
echo "=== disk ==="
df -h / | tail -1