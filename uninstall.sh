#!/usr/bin/env bash

set -euo pipefail

if ! which launchctl &> /dev/null; then
  echo "launchctl not found in PATH, skipping background service removal"
  exit 0
fi

service="com.inflation.ons_cpi_service"
service_domain="gui/$(id -u)"
service_config_filename="${service}.plist"
service_config_file="$HOME/Library/LaunchAgents/${service_config_filename}"


if launchctl list | grep -q $service &> /dev/null; then
  launchctl bootout "$service_domain" "$service_config_file"
  echo "Unloaded background service $service"
else
  echo "Background service $service is not loaded"
fi

if [[ -f "$service_config_file" ]]; then
  rm "$service_config_file"
  echo "Removed background service configuration at $service_config_file"
else
  echo "No background service configuration found at $service_config_file"
fi
