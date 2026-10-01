#!/bin/bash
# Server + MySQL resource probe.
#
# Credentials come from the environment so no secret lives in the repo:
#   export DB_USER=esbuser
#   export DB_PASSWORD='...'
#   export DB_NAME=insurance_platform   # optional, defaults to insurance_platform
set -u

DB_USER="${DB_USER:-esbuser}"
DB_NAME="${DB_NAME:-insurance_platform}"

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

mysql_run() { mysql --defaults-extra-file="$cnf" "$DB_NAME" -e "$1" 2>/dev/null; }

echo "=== Server resources ==="
free -h
df -h / | tail -1
uptime

echo ""
echo "=== Top processes ==="
ps aux --sort=-%cpu | head -10

echo ""
echo "=== MySQL processlist ==="
mysql_run "SHOW FULL PROCESSLIST;"

echo ""
echo "=== MySQL variable timeouts ==="
mysql_run "SHOW VARIABLES LIKE '%timeout%';" | grep -i "connect\|wait\|read\|interactive"

echo ""
echo "=== InnoDB status (lock section) ==="
mysql_run "SHOW ENGINE INNODB STATUS\G" | grep -A30 "LATEST DETECTED DEADLOCK" | head -40