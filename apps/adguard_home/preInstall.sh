#!/bin/bash

# Fail if AdGuardHome.yaml exists
set -e

CONF_DIR="conf"
CONFIG_FILE="AdGuardHome.yaml"

if [ ! -d "$CONF_DIR" ]; then
  mkdir -p "$CONF_DIR"
fi

mv "$CONFIG_FILE" "$CONF_DIR/"

