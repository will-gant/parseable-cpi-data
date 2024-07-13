#!/usr/bin/env bash

set -euo pipefail

if ! which git &> /dev/null; then
  echo "Error: git is not installed."
  exit 1
fi

if ! which python &> /dev/null; then
  echo "Error: python is not installed."
  exit 1
else
  python_version=$(python --version 2>&1)
  if [[ ! $python_version == *"Python 3"* ]]; then
    echo "Error: python 3 is required."
    exit 1
  fi
fi

if ! which pip &> /dev/null; then
  echo "Error: pip is not installed."
  exit 1
fi

get_script_dir() {
  local script_path="$1"
  local script_dir
  script_dir=$(cd "$(dirname "$script_path")" && pwd)
  echo "$script_dir"
}

script_dir=$(get_script_dir "$0")

repo_dir=$(git -C "$script_dir" rev-parse --show-toplevel)

python -m venv "$repo_dir/venv"

source "$repo_dir/venv/bin/activate"

pip install --quiet --requirement "$repo_dir/requirements.txt"

if ! which launchctl &> /dev/null; then
  echo "launchctl not found in PATH, skipping background service setup"
  exit 0
fi

service="com.inflation.ons_cpi_service"
service_config_file="${service}.plist"
service_domain="gui/$(id -u)"

plist_template="$repo_dir/${service}.plist"
plist_target="$HOME/Library/LaunchAgents/${service_config_file}"

if [ ! -f "$plist_template" ]; then
  echo "Error: The template file $service_config_file does not exist in the repository."
  exit 1
fi

sed "s|/path/to/repo|$repo_dir|g" "$plist_template" > "$plist_target"
echo "Copied background service configuration to $plist_target"

if launchctl list  $service &> /dev/null; then
  launchctl bootout "$service_domain" "$plist_target"
  echo "Unloaded pre-existing background service $service"
fi

launchctl bootstrap "$service_domain" "$plist_target"

url="http://localhost:5000"
health_check_url="${url}/health"
health_check_timeout=10
health_check_interval=1

health_check_start=$(date +%s)
health_check_end=$((health_check_start + health_check_timeout))

while true; do
  if curl --silent --fail --output /dev/null "$health_check_url"; then
    echo "Setup completed successfully - app listening at $url"
    break
  fi

  current_time=$(date +%s)
  if [ "$current_time" -ge "$health_check_end" ]; then
    echo "Health check failed."
    exit 1
  fi

  sleep "$health_check_interval"
done

