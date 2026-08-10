#!/bin/bash
set -e

API_KEY="$1"
TAKEOUT_DIR="$2"
# http://localhost
IMMICH_URL="$3"
STATUS_FILE="/tmp/immich-import-takeout.status"

echo "RUNNING" > "$STATUS_FILE"

cleanup() {
	rm -f /tmp/immich-go_Linux_x86_64.tar.gz
	rm -f /usr/local/bin/immich-go

    if [ $? -eq 0 ]; then
        echo "SUCCESS" > "$STATUS_FILE"
    else
        echo "ERROR" > "$STATUS_FILE"
    fi
}
trap cleanup EXIT

echo "--> Verifying Takeout directory: $TAKEOUT_DIR"
if [ ! -d "$TAKEOUT_DIR" ]; then
    echo "Error: Directory not found."
    exit 1
fi

# Download immich-go
if [ ! -f "/usr/local/bin/immich-go" ]; then
    echo "--> Downloading immich-go utility..."
    cd /tmp
    wget -q https://github.com/simulot/immich-go/releases/latest/download/immich-go_Linux_x86_64.tar.gz
    tar -xzf immich-go_Linux_x86_64.tar.gz
    mv immich-go /usr/local/bin/
    chmod +x /usr/local/bin/immich-go
fi

echo "--> Starting Google Takeout import to {$IMMICH_URL}:2283..."
/usr/local/bin/immich-go upload from-google-photos \
  --server="{$IMMICH_URL}:2283" \
  --api-key="$API_KEY" \
  "$TAKEOUT_DIR"

echo "--> Import completed successfully."
