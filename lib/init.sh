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

if ! command -v "$agent_cli" &>/dev/null; then
  die "$agent_cli not found. Install it first or specify a different CLI."
fi

# --- Load from file (--from flag) or choose method ---
from_file=""
for arg in "$@"; do
  case "$arg" in
    --from=*) from_file="${arg#--from=}" ;;
    --from) from_file="__next__" ;;
    *) [ "$from_file" = "__next__" ] && from_file="$arg" ;;
  esac
done

load_recipe() {
  local recipe_file="$1"
  if [ ! -f "$recipe_file" ]; then
    die "Recipe file not found: $recipe_file"
  fi

  # Parse recipe JSON into arrays using python3
  eval "$(python3 -c "
import json, shlex
with open('$recipe_file') as f:
    data = json.load(f)
agents = data['agents']
names = ' '.join(shlex.quote(a['name']) for a in agents)
roles = [shlex.quote(a['role']) for a in agents]
chars = [shlex.quote(a['character']) for a in agents]
autos = [shlex.quote(a['autonomy']) for a in agents]
rules = [shlex.quote(a.get('rules', '')) for a in agents]
leads = [str(i) for i, a in enumerate(agents) if a.get('lead')]
lead_idx = leads[0] if leads else '0'
print(f'agent_names=({names})')
print(f'agent_roles=({\" \".join(roles)})')
print(f'agent_characters=({\" \".join(chars)})')
print(f'agent_autonomies=({\" \".join(autos)})')
print(f'agent_rules=({\" \".join(rules)})')
print(f'lead_idx={lead_idx}')
")"
  agent_count=${#agent_names[@]}
  echo ""
  info "Loaded ${agent_count} agents: ${agent_names[*]}"
  echo -e "${DIM}Lead: ${agent_names[$lead_idx]}${RESET}"
}

if [ -n "$from_file" ] && [ "$from_file" != "__next__" ]; then
  # --from flag: load directly
  load_recipe "$from_file"
else
  # --- Choose method ---
  echo ""

  # Find available recipes
  recipe_dir="$MUSTER_ROOT/recipes"
  declare -a recipe_files=()
  declare -a recipe_names=()
  declare -a recipe_descs=()
  if [ -d "$recipe_dir" ]; then
    for rf in "$recipe_dir"/*.json; do
      [ -f "$rf" ] || continue
      recipe_files+=("$rf")
      rname="$(python3 -c "import json; print(json.load(open('$rf'))['name'])")"
      rdesc="$(python3 -c "import json; print(json.load(open('$rf'))['description'])")"
      recipe_names+=("$rname")
      recipe_descs+=("$rdesc")
    done
  fi

  if [ ${#recipe_files[@]} -gt 0 ]; then
    echo -e "${BOLD}How do you want to set up your team?${RESET}"
    echo "  m) Manual — build from scratch"
    echo "  r) Recipe — choose a premade team"
    read -rp "[m/r]: " setup_method
    setup_method="$(echo "${setup_method:-m}" | tr '[:upper:]' '[:lower:]')"
  else
    setup_method="m"
  fi

  if [ "$setup_method" = "r" ]; then
    # --- Recipe selection ---
    echo ""
    echo -e "${BOLD}Available recipes:${RESET}"
    echo ""
    for i in "${!recipe_files[@]}"; do
      letter=$(printf "\\x$(printf '%02x' $((97 + i)))")
      echo "  $letter) ${recipe_names[$i]} — ${recipe_descs[$i]}"
    done
    echo ""
    read -rp "Pick a recipe [a]: " recipe_choice
    recipe_choice="$(echo "${recipe_choice:-a}" | tr '[:upper:]' '[:lower:]')"
    recipe_idx=$(( $(printf '%d' "'$recipe_choice") - 97 ))
    if [ "$recipe_idx" -lt 0 ] || [ "$recipe_idx" -ge "${#recipe_files[@]}" ]; then
      recipe_idx=0
    fi

    load_recipe "${recipe_files[$recipe_idx]}"
  else
    # --- Manual setup ---
    echo ""
    echo -e "${BOLD}Now let's build your team.${RESET}"
    echo -e "${DIM}5 is the sweet spot. You can add up to 100 if you hate yourself.${RESET}"
    echo ""

    declare -a agent_names=()
    declare -a agent_roles=()
    declare -a agent_characters=()
    declare -a agent_autonomies=()
    declare -a agent_rules=()

    while true; do
      echo -e "${BOLD}--- Agent $((${#agent_names[@]} + 1)) ---${RESET}"
      echo ""

      read -rp "Codename (short, lowercase, no spaces): " aname
      aname="$(echo "$aname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
      if [ -z "$aname" ]; then
        if [ ${#agent_names[@]} -eq 0 ]; then
          warn "You need at least one agent."
          continue
        fi
        break
      fi

      echo ""
      read -rp "What does $aname do? (freeform — e.g. backend, architecture, testing): " arole

      echo ""
      echo -e "${DIM}Pick a fictional character or historical figure whose personality fits this role.${RESET}"
      echo -e "${DIM}Be specific — full name, what they're known for, the version of them you mean.${RESET}"
      echo -e "${DIM}Example: \"Takezo Shinmen, the ronin who fought 61 duels undefeated and wrote The Book of Five Rings\"${RESET}"
      echo -e "${DIM}Example: \"Sherlock Holmes, Arthur Conan Doyle's obsessive detective who sees what everyone else misses\"${RESET}"
      echo -e "${DIM}Example: \"Grace Hopper, the Navy rear admiral who invented the compiler and told people to ask forgiveness, not permission\"${RESET}"
      echo ""
      read -rp "Who is $aname? " acharacter

      echo ""
      echo -e "${DIM}How independently does this agent operate?${RESET}"
      echo "  1) High — never asks, just does"
      echo "  2) Medium — checks in on big decisions"
      echo "  3) Low — confirms before acting"
      read -rp "Autonomy [1/2/3, default 2]: " autonomy_choice
      case "${autonomy_choice:-2}" in
        1) aautonomy="high" ;;
        3) aautonomy="low" ;;
        *) aautonomy="medium" ;;
      esac

      echo ""
      echo -e "${DIM}Any special rules or exemptions for $aname? (optional, press enter to skip)${RESET}"
      echo -e "${DIM}Example: \"Can read any agent's inbox and active work. Reviews all commits.\"${RESET}"
      read -rp "Rules: " arules

      agent_names+=("$aname")
      agent_roles+=("$arole")
      agent_characters+=("$acharacter")
      agent_autonomies+=("$aautonomy")
      agent_rules+=("$arules")

      echo ""
      echo -e "${DIM}${#agent_names[@]} agent(s) so far: ${agent_names[*]}${RESET}"
      read -rp "[a]dd another or [d]one? " add_choice
      add_choice="$(echo "${add_choice:-d}" | tr '[:upper:]' '[:lower:]')"
      [ "$add_choice" != "a" ] && break
      echo ""
    done

    agent_count=${#agent_names[@]}

    # --- Pick the lead ---
    echo ""
    echo -e "${BOLD}Which agent is the lead?${RESET}"
    echo -e "${DIM}The lead coordinates tasks, manages the board, and keeps the team on track. They don't write code.${RESET}"
    echo ""
    for i in "${!agent_names[@]}"; do
      letter=$(printf "\\x$(printf '%02x' $((97 + i)))")
      echo "  $letter) ${agent_names[$i]} — ${agent_roles[$i]}"
    done
    echo ""
    read -rp "Lead [a]: " lead_choice
    lead_choice="$(echo "${lead_choice:-a}" | tr '[:upper:]' '[:lower:]')"
    lead_idx=$(( $(printf '%d' "'$lead_choice") - 97 ))
    if [ "$lead_idx" -lt 0 ] || [ "$lead_idx" -ge "$agent_count" ]; then
      lead_idx=0
    fi
  fi
fi

# --- Assign models ---
echo ""
echo -e "${BOLD}Assigning models${RESET}"
echo -e "${DIM}Tip: opus for the lead and content-heavy work, sonnet for coding${RESET}"
echo ""

declare -a agent_models=()
for i in "${!agent_names[@]}"; do
  if [ "$i" -eq "$lead_idx" ]; then
    default_num="2"
  else
    default_num="1"
  fi
  echo "  1) anthropic/claude-sonnet-4-6"
  echo "  2) anthropic/claude-opus-4-6"
  read -rp "${agent_names[$i]} [default $default_num]: " model_choice
  case "${model_choice:-$default_num}" in
    2) agent_models+=("anthropic/claude-opus-4-6") ;;
    *) agent_models+=("anthropic/claude-sonnet-4-6") ;;
  esac
done

# --- Build JSON ---
agents_json="["
for i in "${!agent_names[@]}"; do
  [ "$i" -gt 0 ] && agents_json+=","
  is_lead=$([ "$i" -eq "$lead_idx" ] && echo "true" || echo "false")
  agents_json+="
    {
      \"name\": \"${agent_names[$i]}\",
      \"role\": \"${agent_roles[$i]}\",
      \"character\": \"${agent_characters[$i]}\",
      \"autonomy\": \"${agent_autonomies[$i]}\",
      \"model\": \"${agent_models[$i]}\",
      \"rules\": \"${agent_rules[$i]}\",
      \"lead\": $is_lead
    }"
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
  agent_rules="$(get_agent_field "$agent_name" "rules")"

  if [ "$agent_lead" = "True" ]; then
    workshopping="Yes — this is the primary brainstorming partner. Workshops with the $user_title directly."
    boundary_note="You own comms/board/ and comms/docs/. You coordinate the team — assign tasks, unblock people, and keep everyone's workspace clean. If someone's inbox is piling up or active/ is stale, tell them to sort it out. You do NOT write code."
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
$([ -n "$agent_rules" ] && printf "\n## Special Rules\n\n%s" "$agent_rules")

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
