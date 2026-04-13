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

if [ "$SIGNUP_STATUS" -ne 200 ] && [ "$SIGNUP_STATUS" -ne 201 ]; then
  echo "Failed to create admin user (HTTP $SIGNUP_STATUS). It may already exist."
  # Exit with code 0 so the user can manually create user, etc. if script fails
  exit 0
fi

# Authenticate user to get the Access Token
echo "Authenticating..."
LOGIN_RES=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

ACCESS_TOKEN=$(echo "$LOGIN_RES" | jq -r '.accessToken')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "Failed to retrieve access token."
    exit 0
fi

# Fetch, modify, and update the System Configuration
echo "Configuring storage template and disabling version check..."
CONFIG=$(curl -s -X GET "$API_URL/system-config" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

# Modify the config
UPDATED_CONFIG=$(echo "$CONFIG" | jq '
  .newVersionCheck.enabled = false |
  .storageTemplate.enabled = true |
  .storageTemplate.template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}"
')

# Push new configuration back
CONFIG_UPDATE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$API_URL/system-config" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "$UPDATED_CONFIG")

if [ "$CONFIG_UPDATE_STATUS" -eq 200 ]; then
    echo "System configuration updated"
else
    echo "Warning: Failed to update system configuration (HTTP $CONFIG_UPDATE_STATUS)."
fi

# Mark admin onboarding as complete to skip welcome screens
echo "Marking initial setup as complete..."
ONBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/system-metadata/admin-onboarding" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"isOnboarded": true}')

if [ "$ONBOARD_STATUS" -eq 200 ] || [ "$ONBOARD_STATUS" -eq 201 ] || [ "$ONBOARD_STATUS" -eq 204 ]; then
    echo "Setup screens bypassed"
else
    echo "Warning: Failed to complete onboarding (HTTP $ONBOARD_STATUS)."
fi

# Mark user onboarding as complete
echo "Marking user welcome screen as complete..."
USER_ONBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$API_URL/users/me/onboarding" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"isOnboarded": true}')

if [ "$USER_ONBOARD_STATUS" -eq 200 ] || [ "$USER_ONBOARD_STATUS" -eq 201 ] || [ "$USER_ONBOARD_STATUS" -eq 204 ]; then
    echo "User welcome screens bypassed successfully."
else
    echo "Warning: Failed to complete user onboarding (HTTP $USER_ONBOARD_STATUS)."
fi

echo "Immich init complete!"
exit 0
