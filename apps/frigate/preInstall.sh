#!/bin/bash

set -e

COMPOSE_FILE="docker-compose.yml"
JSON_FILE="preInstallData.json"

# Get camera count and calculate SHM
SHM_SIZE=$(python3 -c '
import json
import math
import sys

try:
    with open("'$JSON_FILE'", "r") as f:
        data = json.load(f)
        cameras = int(data.get("cameras", 0))

    if cameras <= 0:
        print("Error: Invalid or missing camera count in JSON.")
        sys.exit(1)

    # Formula based on Frigate documentation for 720p + logs
    mb_size = (((1280 * 720 * 1.5 * 20 + 270480) / 1048576) * cameras + 40)
    
    # Round up to the nearest megabyte for a clean integer
    print(f"{math.ceil(mb_size)}mb")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
')

# Update docker compose file
sed -i -E "s/^([[:space:]]+)shm_size:[^#]*(.*)/\1shm_size: \"$SHM_SIZE\" \2/" "$COMPOSE_FILE"
