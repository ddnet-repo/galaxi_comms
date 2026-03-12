#!/usr/bin/env bash
# Muster — Shared functions

set -euo pipefail

MUSTER_VERSION="0.1.3"

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
  # Simple json parse — agent names from team.json
  grep '"name"' "$root/comms/team.json" | sed 's/.*: *"\([^"]*\)".*/\1/'
}

# Get agent count
get_agent_count() {
  local root
  root="$(find_comms_root)" || { echo "0"; return 1; }
  grep -c '"name"' "$root/comms/team.json" 2>/dev/null || echo "0"
}

# Get a field from an agent's entry in team.json
# Usage: get_agent_field <agent_name> <field>
get_agent_field() {
  local root name="$1" field="$2"
  root="$(find_comms_root)" || return 1
  # Use python for reliable json parsing if available, else awk
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

# Count .md files in a directory
count_md() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# Detect file watcher
detect_watcher() {
  if command -v inotifywait &>/dev/null; then
    echo "inotify"
  elif command -v fswatch &>/dev/null; then
    echo "fswatch"
  else
    echo "none"
  fi
}

# Check dependencies
check_deps() {
  local missing=()
  command -v tmux &>/dev/null || missing+=("tmux")
  
  local watcher
  watcher="$(detect_watcher)"
  if [ "$watcher" = "none" ]; then
    missing+=("inotifywait or fswatch")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}Missing dependencies:${RESET} ${missing[*]}"
    echo "Install them and try again."
    return 1
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
