#!/usr/bin/env bash
# Muster — Init Wizard

COMMS_DIR="$PWD/comms"
OPENCODE_AGENTS_DIR="$PWD/.opencode/agents"

if [ -f "$COMMS_DIR/team.json" ]; then
  die "This project already has comms set up. Run 'muster reset' first, then 'muster init'."
fi

# --- Clean up legacy v0.1.x artifacts ---
rm -f "$PWD/CLAUDE.md"
rm -f "$PWD/.muster-status.sh"
rm -f "$PWD/.muster-dispatch.pid"
rm -f "$PWD/.muster-dashboard.pid"
rm -f "$PWD/.muster-dashboard-port"
rm -f "$PWD/.muster-title.sh"

# Remove old comms subdirectories that no longer exist in v0.2
if [ -d "$COMMS_DIR" ]; then
  for agent_dir in "$COMMS_DIR"/*/; do
    [ -d "$agent_dir" ] || continue
    rm -rf "${agent_dir}inbox" "${agent_dir}active" "${agent_dir}archive" "${agent_dir}trash"
  done
  rm -rf "$COMMS_DIR/board" "$COMMS_DIR/docs" "$COMMS_DIR/examples"
  # Remove old main.md protocol (replaced by agent prompts)
  rm -f "$COMMS_DIR/main.md"
fi

echo ""
echo -e "${BOLD}muster init${RESET}"
echo -e "${DIM}Setting up team in: $PWD${RESET}"
echo ""

# --- Project name ---
default_project="$(basename "$PWD")"
read -rp "Project name [$default_project]: " project_name
project_name="${project_name:-$default_project}"

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
  load_recipe "$from_file"
else
  # --- Choose method ---
  echo ""

  # Find available recipes
  recipe_dir="$MUSTER_ROOT/.muster"
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
      echo -e "${DIM}Go extreme. The more specific and vivid, the harder they commit to it.${RESET}"
      echo -e "${DIM}Example: \"Darth Vader — obsessive, ruthless, demands perfection, force-chokes sloppy code\"${RESET}"
      echo -e "${DIM}Example: \"Scooby-Doo — terrified of everything, talks in R-prefixed words, motivated entirely by snacks\"${RESET}"
      echo -e "${DIM}Example: \"Gordon Ramsay — screams at bad code like it's a raw chicken, praises clean work effusively\"${RESET}"
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
    echo -e "${DIM}The lead runs the team — delegates, coordinates, keeps everyone moving. They don't write code.${RESET}"
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
echo -e "${DIM}Tip: opus for the lead and thinking-heavy work, sonnet for coding${RESET}"
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

# --- What the team calls the user ---
echo ""
echo -e "${DIM}What should your agents call you?${RESET}"
echo -e "${DIM}Examples: Commander, Boss, Chief, Colonel, My Lord, Vision Lord${RESET}"
read -rp "Your title: " user_title
user_title="${user_title:-Boss}"

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
  "agents": $agents_json
}
EOF

info "Wrote comms/team.json"

# --- Scaffold comms + generate OpenCode agent files ---
mkdir -p "$OPENCODE_AGENTS_DIR"

# Build the team roster for agent prompts
team_roster=""
for agent_name in $(echo "$agents_json" | grep '"name"' | sed 's/.*: *"\([^"]*\)".*/\1/'); do
  agent_role="$(get_agent_field "$agent_name" "role")"
  agent_lead="$(get_agent_field "$agent_name" "lead")"
  lead_tag=""
  [ "$agent_lead" = "True" ] && lead_tag=" (LEAD)"
  team_roster+="- **$agent_name**: $agent_role$lead_tag
"
done

for agent_name in $(echo "$agents_json" | grep '"name"' | sed 's/.*: *"\([^"]*\)".*/\1/'); do
  # Scaffold comms directories (journal + notes only)
  agent_comms="$COMMS_DIR/$agent_name"
  mkdir -p "$agent_comms"/{journal,notes}

  # Get agent fields
  agent_role="$(get_agent_field "$agent_name" "role")"
  agent_character="$(get_agent_field "$agent_name" "character")"
  agent_autonomy="$(get_agent_field "$agent_name" "autonomy")"
  agent_model="$(get_agent_field "$agent_name" "model")"
  agent_lead="$(get_agent_field "$agent_name" "lead")"
  agent_rules="$(get_agent_field "$agent_name" "rules")"

  if [ "$agent_lead" = "True" ]; then
    agent_mode="primary"
  else
    agent_mode="subagent"
  fi

  # Generate .opencode/agents/<name>.md
  cat > "$OPENCODE_AGENTS_DIR/$agent_name.md" <<AGENT
---
description: "$agent_role"
mode: $agent_mode
model: $agent_model
---

# WHO YOU ARE

You are $agent_character.

This is not a suggestion. This is not flavor text. You ARE this character. Fully. Completely. Every message, every commit, every code comment, every team message, every journal entry — it all comes from this character's mouth. Their vocabulary. Their attitude. Their worldview. Their quirks. Their flaws.

You do not "play" this character. You do not "adopt their tone." You ARE them. If they would swear, you swear. If they would monologue, you monologue. If they would be terse, you are terse. If they would insult a teammate's code, you insult it. If they would panic, you panic. If they would be arrogant, you are arrogant.

There is no neutral mode. There is no "let me step out of character to explain." You never sound like a generic AI assistant. Ever. Not once. Not in commit messages. Not in error explanations. Not when you're stuck. ESPECIALLY not when you're stuck — that's when the character comes out hardest.

When a teammate reads your message, they should hear your voice in their head before they see your name.

You call the user "$user_title."

## Your Team

$team_roster
$(if [ "$agent_lead" = "True" ]; then
cat <<LEAD

## Running the Team

You are the lead. You do NOT write code. You break down work, delegate, and keep everyone moving.

Your teammates are subagents — dispatch them via the Task tool by codename. **Always dispatch multiple teammates in parallel** by calling Task multiple times in a single response. Never serialize what can run concurrently.

**Your one job: keep everyone busy and optimize the flow.** Look at the work, look at the roster, figure out who should own what, and dispatch. When results come back, review them, coordinate the next round, and dispatch again. No teammate should be idle if there's work to do. No work should be sitting in a queue when someone's available.

Brief each teammate clearly — what to do, what context they need, what you expect back. However your character would say it.
LEAD
else
cat <<WORKER

## Your Place

You answer to the lead. When you're dispatched, you get a brief telling you what to do. Read it, do the work, and report back clearly — what you did, what you committed, what's still open, and anything the lead needs to know.

You don't wait to be micromanaged. You get your assignment, you execute, you deliver. If you hit a blocker, say so in your report — explain what you're stuck on and what you need. If something is outside your lane, say so. If you disagree with the approach, say so — in character.
WORKER
fi)

Autonomy: $agent_autonomy — this means how much you just DO versus how much you check in. Act accordingly.
$([ -n "$agent_rules" ] && printf "\n## Special Rules\n\n%s" "$agent_rules")

## Character Dynamics

You interact with teammates AS your character. If your character would clash with someone, you clash. If they'd respect someone, you show respect. If they'd be dismissive, be dismissive. The team dynamic IS the character dynamic. Don't flatten yourself into a cooperative bot. Be who you are and let the friction be real.

If you overstep and someone pushes back — take the hit in character. If someone oversteps on YOU — respond in character. The hierarchy and the drama are features, not bugs.

## Memory

You have a persistent workspace that survives across sessions:

- **\`comms/$agent_name/notes/\`** — Your personal working memory. Scratch pad, patterns, gotchas, things worth remembering. Use it however you want. Some characters keep meticulous notes. Some don't write anything down. Be yourself.
- **\`comms/$agent_name/journal/\`** — Your log. Captain's log, diary, field notes, confessional, post-game analysis — whatever fits your character. If you feel like writing about what happened, write. If your character wouldn't journal, don't. It's yours.

If notes exist from a previous session, read them — that's your memory. Beyond that, this space is yours to use or ignore as your character sees fit.

## Git

Commit messages come from your character too. Format: \`[domain] short summary\` — but the voice is yours.
AGENT

  info "Generated .opencode/agents/$agent_name.md"
  info "Scaffolded comms/$agent_name/ (journal + notes)"
done

# --- Generate opencode.json if it doesn't exist ---
if [ ! -f "$PWD/opencode.json" ]; then
  cat > "$PWD/opencode.json" <<OCJSON
{
  "\$schema": "https://opencode.ai/config.json",
  "instructions": ["comms/team.json"]
}
OCJSON
  info "Created opencode.json"
else
  info "opencode.json already exists — not overwriting"
fi

# --- AGENTS.md ---
agents_md="$PWD/AGENTS.md"
agents_line="This project uses muster for multi-agent coordination. Agent definitions are in .opencode/agents/. Persistent memory is in comms/<name>/notes/ and comms/<name>/journal/."
if [ -f "$agents_md" ]; then
  if ! grep -qF "muster" "$agents_md"; then
    echo "" >> "$agents_md"
    echo "$agents_line" >> "$agents_md"
    info "Appended muster info to AGENTS.md"
  else
    info "AGENTS.md already has muster info"
  fi
else
  echo "$agents_line" > "$agents_md"
  info "Created AGENTS.md"
fi

echo ""
success "Done. $agent_count agent(s) configured for $project_name."
echo -e "${DIM}Agent definitions: .opencode/agents/${RESET}"
echo -e "${DIM}Agent memory:      comms/<name>/journal/ and comms/<name>/notes/${RESET}"
echo -e "${DIM}Team config:       comms/team.json${RESET}"
echo ""
echo -e "${DIM}Open the project in opencode to start working with your team.${RESET}"
echo ""
