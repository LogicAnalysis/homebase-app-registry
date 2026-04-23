#!/bin/bash

# Fail if AdGuardHome.yaml exists
set -e

# Ensure storage dir exists
mkdir -p /app/data/apps/storage

# Extract json values for the env file
FB_USER=$(jq -r '.username' preInstallData.json)
FB_PASS=$(jq -r '.password' preInstallData.json)

cat <<EOF > preInstallData.env
FB_USERNAME=$FB_USER
FB_PASSWORD=$FB_PASS
EOF

# Create empty db file so Docker doesn't create a directory
touch filebrowser.db

# 4. Start the Docker Compose stack
echo "Starting Filebrowser..."
docker compose up -d

# Wait for container to boot and read env file
sleep 5

# Clean up sensitive files
rm preInstallData.json
echo "" > preInstallData.env
