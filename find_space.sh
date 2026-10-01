#!/bin/bash
# Locate login procs and report disk usage on the host.
#
# Credentials come from the environment so no secret lives in the repo:
#   export DB_USER=esbuser
#   export DB_PASSWORD='...'
#   export DB_NAME=insurance_platform   # optional, defaults to insurance_platform
#
# LMK_ROOT can point at the deployed services if they are not in the default
# location:  export LMK_ROOT=/root/home/lmk
set -u

DB_USER="${DB_USER:-esbuser}"
DB_NAME="${DB_NAME:-insurance_platform}"
LMK_ROOT="${LMK_ROOT:-/root/home/lmk}"

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

echo '=== procedures ==='
mysql --defaults-extra-file="$cnf" -N "$DB_NAME" \
  -e "SHOW PROCEDURE STATUS WHERE Db='$DB_NAME'" 2>/dev/null \
  | awk '{print $1}' | sort | grep -i login

echo "=== lmk/server top ==="
du -sh "$LMK_ROOT"/server/* 2>/dev/null | sort -rh | head -8

echo "=== lmk/emails sample ==="
ls "$LMK_ROOT"/emails 2>/dev/null | head -5

echo "=== lmk/sms sample ==="
ls "$LMK_ROOT"/sms 2>/dev/null | head -5

echo "=== big files ==="
find "$LMK_ROOT" /root/home/bimadline -maxdepth 3 \
  \( -name '*.log' -o -name '*.tar*' -o -name '*.zip' -o -name 'core*' -o -name '*.gz' -o -name '*.txt' \) \
  -size +50M 2>/dev/null | head -20

echo '=== bimadline purchaseinsuranseservice ==='
du -sh /root/home/bimadline/purchaseinsuranseservice/* 2>/dev/null | sort -rh | head -8