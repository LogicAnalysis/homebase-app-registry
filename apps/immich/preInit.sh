#!/bin/bash
set -e

API_URL="http://127.0.0.1:2283/api"
DATA_FILE="preInitData.json"

# Parse JSON to extract the user parameters
EMAIL=$(jq -r '.email' "$DATA_FILE")
PASSWORD=$(jq -r '.password' "$DATA_FILE")
NAME=$(jq -r '.name' "$DATA_FILE")

echo "Waiting for Immich server to start..."
until [ "$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/server/ping")" -eq 200 ]; do
    sleep 3
done
echo "Immich server is active."

echo "Creating admin user..."
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/auth/admin-sign-up" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\", \"name\": \"$NAME\"}")

if [ "$STATUS_CODE" -eq 200 ] || [ "$STATUS_CODE" -eq 201 ]; then
  echo "Admin user successfully created."
  exit 0
else
  echo "Failed to create admin user. HTTP Status: $STATUS_CODE"
  exit 1
fi
