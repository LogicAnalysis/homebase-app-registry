#!/bin/bash

set -e

CONFIG_FILE="data/config.yaml"

FB_USER=$(jq -r '.username' preInstallData.json)
FB_PASS=$(jq -r '.password' preInstallData.json)

sed -i "s|^[[:space:]]*adminUsername:.*|  adminUsername: ${FB_USER}|" "$CONFIG_FILE"
sed -i "s|^[[:space:]]*adminPassword:.*|  adminPassword: ${FB_PASS}|" "$CONFIG_FILE"

docker compose up -d

sleep 10

sed -i '/^[[:space:]]*adminPassword:/d' "$CONFIG_FILE"

rm -f preInstallData.json
