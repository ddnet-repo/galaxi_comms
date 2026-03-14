#!/usr/bin/env bash
# Muster — Shared functions

set -euo pipefail

MUSTER_VERSION="0.2.0"

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# Find the comms directory (walk up from cwd)
find_comms_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/comms/team.json" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Read team.json and extract agent names as array
get_agents() {
  local root
  root="$(find_comms_root)" || { echo "No muster project found." >&2; return 1; }
  grep '"name"' "$root/comms/team.json" | sed 's/.*: *"\([^"]*\)".*/\1/'
}

# Get agent count
get_agent_count() {
  local root
  root="$(find_comms_root)" || { echo "0"; return 1; }
  grep -c '"name"' "$root/comms/team.json" 2>/dev/null || echo "0"
}

# Get a field from an agent's entry in team.json
get_agent_field() {
  local root name="$1" field="$2"
  root="$(find_comms_root)" || return 1
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$root/comms/team.json') as f:
    data = json.load(f)
for agent in data['agents']:
    if agent['name'] == '$name':
        print(agent.get('$field', ''))
        break
"
  else
    echo ""
  fi
}

die() {
  echo -e "${RED}$1${RESET}" >&2
  exit 1
}

info() {
  echo -e "${CYAN}$1${RESET}"
}

success() {
  echo -e "${GREEN}$1${RESET}"
}

warn() {
  echo -e "${YELLOW}$1${RESET}"
}
