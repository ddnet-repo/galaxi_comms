#!/usr/bin/env bash
# Muster — Remove a team member

root="$(find_comms_root)" || die "No muster project found."

COMMS_DIR="$root/comms"
TEAM_JSON="$COMMS_DIR/team.json"

if [ -z "${1:-}" ]; then
  echo ""
  echo -e "${BOLD}Current team:${RESET}"
  get_agents | while read -r name; do
    echo "  - $name"
  done
  echo ""
  read -rp "Remove who? " agent_name
else
  agent_name="$1"
fi

[ -z "$agent_name" ] && die "No agent specified."

if [ ! -d "$COMMS_DIR/$agent_name" ]; then
  die "Agent '$agent_name' not found."
fi

echo ""
read -rp "Remove $agent_name and all their files? [y/N]: " confirm
confirm="$(echo "${confirm:-n}" | tr '[:upper:]' '[:lower:]')"
[ "$confirm" != "y" ] && die "Cancelled."

# Remove from team.json
python3 -c "
import json
with open('$TEAM_JSON') as f:
    data = json.load(f)
data['agents'] = [a for a in data['agents'] if a['name'] != '$agent_name']
with open('$TEAM_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"

# Remove directory
rm -rf "$COMMS_DIR/$agent_name"

success "Removed $agent_name."
echo -e "${DIM}Restart muster to apply: muster stop && muster start${RESET}"
echo ""
