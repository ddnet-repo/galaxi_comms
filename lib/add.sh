#!/usr/bin/env bash
# Muster — Add a team member

root="$(find_comms_root)" || die "No muster project found. Run 'muster init' first."

COMMS_DIR="$root/comms"
TEAM_JSON="$COMMS_DIR/team.json"
user_title="$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['user_title'])")"

echo ""
echo -e "${BOLD}Add a team member${RESET}"
echo ""

read -rp "Codename (short, lowercase, no spaces): " agent_name
agent_name="$(echo "$agent_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
[ -z "$agent_name" ] && die "Codename required."

if [ -d "$COMMS_DIR/$agent_name" ]; then
  die "Agent '$agent_name' already exists."
fi

echo ""
read -rp "What does $agent_name do? " agent_role

echo ""
echo -e "${DIM}Pick a fictional character or historical figure whose personality fits this role.${RESET}"
echo -e "${DIM}Be specific — full name, what they're known for, the version of them you mean.${RESET}"
echo ""
read -rp "Who is $agent_name? " agent_character

echo ""
echo "  1) High — never asks, just does"
echo "  2) Medium — checks in on big decisions"
echo "  3) Low — confirms before acting"
read -rp "Autonomy [1/2/3, default 2]: " autonomy_choice
case "${autonomy_choice:-2}" in
  1) autonomy="high" ;;
  3) autonomy="low" ;;
  *) autonomy="medium" ;;
esac

echo ""
read -rp "Is $agent_name the team lead? [y/N]: " is_lead
is_lead="$(echo "${is_lead:-n}" | tr '[:upper:]' '[:lower:]')"
lead_bool=$([ "$is_lead" = "y" ] && echo "true" || echo "false")

# Add to team.json
python3 -c "
import json
with open('$TEAM_JSON') as f:
    data = json.load(f)
data['agents'].append({
    'name': '$agent_name',
    'role': '$agent_role',
    'character': '$agent_character',
    'autonomy': '$autonomy',
    'lead': $lead_bool
})
with open('$TEAM_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"

# Scaffold directories
agent_dir="$COMMS_DIR/$agent_name"
mkdir -p "$agent_dir"/{inbox,active,archive,trash,notes,journal}

if [ "$is_lead" = "y" ]; then
  workshopping="Yes — this is the primary brainstorming partner. Workshops with the $user_title directly."
  boundary_note="You manage comms/board/. You do NOT write code. You write plans, specs, and assign work."
else
  workshopping="No — executes tasks, routes questions through inboxes or the board."
  boundary_note="Stay in your lane. If something is outside your role, drop it on the board or message the lead."
fi

cat > "$agent_dir/profile.md" <<PROFILE
# $agent_name

You are $agent_character.

You call the user "$user_title."

## Role

$agent_role

## Autonomy

$autonomy

## Workshopping

$workshopping

## Boundaries

$boundary_note

## Loop Extensions

<!-- Add custom steps this agent runs as part of the loop. -->

## Journal Tendency

Minimal — bullet points at session end.

## Session End

- Commit any completed work.
- Update notes/ if you learned something permanent.
- Write a journal entry if your tendency calls for it.
PROFILE

success "Added $agent_name."
echo -e "${DIM}Restart muster to pick up the new agent: muster stop && muster start${RESET}"
echo ""
