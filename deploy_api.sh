#!/bin/bash
set -e

SUDO_PASS="Master@1"
DEPLOY_DIR="/root/home/insurancePlatform/insuranceApi"
SERVICE="kestrel-insuranceApi-server.service"
BACKUP="/tmp/appsettings_backup_api.json"

echo "$SUDO_PASS" | sudo -S bash -c '
set -e
DEPLOY_DIR="/root/home/insurancePlatform/insuranceApi"
SERVICE="kestrel-insuranceApi-server.service"
BACKUP="/tmp/appsettings_backup_api.json"

cp "$DEPLOY_DIR/appsettings.json" "$BACKUP" 2>/dev/null || true
systemctl stop "$SERVICE"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
unzip -o /tmp/publish_api.zip -d "$DEPLOY_DIR" > /dev/null
cp "$BACKUP" "$DEPLOY_DIR/appsettings.json" 2>/dev/null || true
find "$DEPLOY_DIR/wwwroot" -name "*.br" -delete 2>/dev/null || true
find "$DEPLOY_DIR/wwwroot" -name "*.gz" -delete 2>/dev/null || true
chmod 755 "$DEPLOY_DIR" 2>/dev/null || true
chmod +x "$DEPLOY_DIR/InsurancePlatform.Api" 2>/dev/null || true
systemctl start "$SERVICE"
sleep 2
systemctl is-active "$SERVICE"
'
