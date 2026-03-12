#!/usr/bin/env bash
# Muster — Init Wizard

COMMS_DIR="$PWD/comms"

if [ -f "$COMMS_DIR/team.json" ]; then
  die "This project already has comms set up. Run 'muster add' to add team members."
fi

echo ""
echo -e "${BOLD}muster init${RESET}"
echo -e "${DIM}Setting up team comms in: $PWD${RESET}"
echo ""

# --- Project name ---
default_project="$(basename "$PWD")"
read -rp "Project name [$default_project]: " project_name
project_name="${project_name:-$default_project}"

# --- What the team calls the user ---
echo ""
echo -e "${DIM}What should your agents call you?${RESET}"
echo -e "${DIM}Examples: Commander, Boss, Vision Lord, Chief, Colonel${RESET}"
read -rp "Your title: " user_title
user_title="${user_title:-Boss}"

# --- Which agent tool ---
echo ""
echo -e "${DIM}What CLI do your agents run? (e.g. opencode, claude, aider)${RESET}"
read -rp "Agent CLI command [opencode]: " agent_cli
agent_cli="${agent_cli:-opencode}"

# --- Team members ---
echo ""
echo -e "${BOLD}Now let's build your team.${RESET}"
echo ""

agents_json="["
agent_count=0

while true; do
  echo -e "${BOLD}--- Agent $((agent_count + 1)) ---${RESET}"
  echo ""

  # Codename
  read -rp "Codename (short, lowercase, no spaces): " agent_name
  agent_name="$(echo "$agent_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
  if [ -z "$agent_name" ]; then
    if [ "$agent_count" -eq 0 ]; then
      warn "You need at least one agent."
      continue
    fi
    break
  fi

  # What they do
  echo ""
  read -rp "What does $agent_name do? (freeform — e.g. backend, architecture, testing): " agent_role

  # Who are they
  echo ""
  echo -e "${DIM}Pick a fictional character or historical figure whose personality fits this role.${RESET}"
  echo -e "${DIM}Be specific — full name, what they're known for, the version of them you mean.${RESET}"
  echo -e "${DIM}Example: \"Takezo Shinmen, the ronin who fought 61 duels undefeated and wrote The Book of Five Rings\"${RESET}"
  echo -e "${DIM}Example: \"Sherlock Holmes, Arthur Conan Doyle's obsessive detective who sees what everyone else misses\"${RESET}"
  echo -e "${DIM}Example: \"Grace Hopper, the Navy rear admiral who invented the compiler and told people to ask forgiveness, not permission\"${RESET}"
  echo ""
  read -rp "Who is $agent_name? " agent_character

  # Autonomy
  echo ""
  echo -e "${DIM}How independently does this agent operate?${RESET}"
  echo "  1) High — never asks, just does"
  echo "  2) Medium — checks in on big decisions"
  echo "  3) Low — confirms before acting"
  read -rp "Autonomy [1/2/3, default 2]: " autonomy_choice
  case "${autonomy_choice:-2}" in
    1) autonomy="high" ;;
    3) autonomy="low" ;;
    *) autonomy="medium" ;;
  esac

  # Is this the lead/architect?
  echo ""
  read -rp "Is $agent_name the team lead / architect? [y/N]: " is_lead
  is_lead="$(echo "${is_lead:-n}" | tr '[:upper:]' '[:lower:]')"

  # Build JSON entry
  [ "$agent_count" -gt 0 ] && agents_json+=","
  agents_json+="
    {
      \"name\": \"$agent_name\",
      \"role\": \"$agent_role\",
      \"character\": \"$agent_character\",
      \"autonomy\": \"$autonomy\",
      \"lead\": $([ "$is_lead" = "y" ] && echo "true" || echo "false")
    }"

  agent_count=$((agent_count + 1))

  echo ""
  read -rp "Add another agent? [y/N]: " add_more
  add_more="$(echo "${add_more:-n}" | tr '[:upper:]' '[:lower:]')"
  [ "$add_more" != "y" ] && break
  echo ""
done

agents_json+="
  ]"

# --- Write team.json ---
mkdir -p "$COMMS_DIR"

cat > "$COMMS_DIR/team.json" <<EOF
{
  "project": "$project_name",
  "user_title": "$user_title",
  "agent_cli": "$agent_cli",
  "agents": $agents_json
}
EOF

info "Wrote comms/team.json"

# --- Scaffold agent directories ---
for agent_name in $(echo "$agents_json" | grep '"name"' | sed 's/.*: *"\([^"]*\)".*/\1/'); do
  agent_dir="$COMMS_DIR/$agent_name"
  mkdir -p "$agent_dir"/{inbox,active,archive,trash,notes,journal}

  # Generate profile.md
  agent_role="$(get_agent_field "$agent_name" "role")"
  agent_character="$(get_agent_field "$agent_name" "character")"
  agent_autonomy="$(get_agent_field "$agent_name" "autonomy")"
  agent_lead="$(get_agent_field "$agent_name" "lead")"

  if [ "$agent_lead" = "True" ]; then
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

$agent_autonomy

## Workshopping

$workshopping

## Boundaries

$boundary_note

## Loop Extensions

<!-- Add custom steps this agent runs as part of the loop. Examples: -->
<!-- - Run tests after every commit -->
<!-- - Update notes/ when you learn something worth remembering -->

## Journal Tendency

Minimal — bullet points at session end.

## Session End

- Commit any completed work.
- Update notes/ if you learned something permanent.
- Write a journal entry if your tendency calls for it.
PROFILE

  info "Scaffolded comms/$agent_name/"
done

# --- Create board directory (lead-owned) ---
mkdir -p "$COMMS_DIR/board"
cat > "$COMMS_DIR/board/README.md" <<BOARD
# Task Board

This directory is the single source of truth for task state.

The team lead owns this directory. Everyone reads it, only the lead writes to it.

Organize however makes sense. One file, ten files, by feature, by sprint — the lead decides.
BOARD

info "Created comms/board/"

# --- Create docs directory ---
mkdir -p "$COMMS_DIR/docs"
info "Created comms/docs/"

# --- Generate main.md from template ---
cp "$MUSTER_ROOT/templates/main.md" "$COMMS_DIR/main.md"

# Build team table
team_table=""
for agent_name in $(echo "$agents_json" | grep '"name"' | sed 's/.*: *"\([^"]*\)".*/\1/'); do
  agent_role="$(get_agent_field "$agent_name" "role")"
  agent_lead="$(get_agent_field "$agent_name" "lead")"
  lead_tag=""
  [ "$agent_lead" = "True" ] && lead_tag=" (Lead)"
  team_table+="| $agent_name | $agent_role$lead_tag | \`comms/$agent_name/\` |
"
done

# Replace placeholder in main.md
if command -v python3 &>/dev/null; then
  python3 -c "
import sys
content = open('$COMMS_DIR/main.md').read()
content = content.replace('<!-- TEAM_TABLE -->', '''$team_table'''.strip())
content = content.replace('<!-- USER_TITLE -->', '$user_title')
content = content.replace('<!-- PROJECT -->', '$project_name')
open('$COMMS_DIR/main.md', 'w').write(content)
"
fi

info "Generated comms/main.md"

# --- CLAUDE.md ---
claude_md="$PWD/CLAUDE.md"
claude_line="Read \`comms/main.md\` and follow its instructions before doing anything else."
if [ -f "$claude_md" ]; then
  if ! grep -qF "$claude_line" "$claude_md"; then
    echo "" >> "$claude_md"
    echo "$claude_line" >> "$claude_md"
    info "Appended to CLAUDE.md"
  else
    info "CLAUDE.md already configured"
  fi
else
  echo "$claude_line" > "$claude_md"
  info "Created CLAUDE.md"
fi

echo ""
success "Done. $agent_count agent(s) configured for $project_name."
echo -e "${DIM}Run 'muster start' to launch your team.${RESET}"
echo ""
