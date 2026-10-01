#!/bin/bash
# Login proc / latency probe.
#
# Credentials come from the environment so no secret lives in the repo:
#   export DB_USER=esbuser
#   export DB_PASSWORD='...'
#   export DB_NAME=insurance_platform   # optional, defaults to insurance_platform
#
# DB_PASSWORD is passed via a defaults-extra-file rather than -p so it does not
# appear in the process list.
set -u

DB_USER="${DB_USER:-esbuser}"
DB_NAME="${DB_NAME:-insurance_platform}"
API_LOGIN_URL="${API_LOGIN_URL:-https://insuranceapi.riziki.app/api/auth/login}"

if [ -z "${DB_PASSWORD:-}" ]; then
  echo "DB_PASSWORD is not set. Export it before running." >&2
  exit 1
fi

cnf="$(mktemp)"
trap 'rm -f "$cnf"' EXIT
chmod 600 "$cnf"
cat > "$cnf" <<EOF
[client]
user=$DB_USER
password=$DB_PASSWORD
EOF

mysql_run() { mysql --defaults-extra-file="$cnf" -N "$DB_NAME" -e "$1" 2>/dev/null; }

echo "=== Login proc name check ==="
mysql_run "SHOW CREATE PROCEDURE usp_User_Login" | head -3

echo ""
echo "=== DB proc speed test ==="
time mysql_run "CALL usp_User_Login('90000002','wrongpass',@a,@b); SELECT CONCAT(@a,'|',LEFT(@b,60));"

echo ""
echo "=== API login speed test ==="
curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' \
  -X POST "$API_LOGIN_URL" \
  -H 'Content-Type: application/json' -H 'x-channel: BACKOFFICE' \
  -d '{"idNo":"90000002","password":"wrongpass"}'

echo ""
echo "=== disk ==="
df -h / | tail -1