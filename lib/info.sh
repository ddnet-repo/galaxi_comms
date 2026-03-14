#!/usr/bin/env bash
# Muster — Project info

root="$(find_comms_root)" || die "No muster project found. Run 'muster init' first."

COMMS_DIR="$root/comms"
TEAM_JSON="$COMMS_DIR/team.json"

project="$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['project'])")"
user_title="$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['user_title'])")"

echo ""
echo -e "${BOLD}$project${RESET}"
echo -e "${DIM}$root${RESET}"
echo ""
echo -e "  ${BOLD}Title:${RESET}  $user_title"
echo ""
echo -e "  ${BOLD}AGENT            MODEL                          ROLE${RESET}"
echo "  ---------------  -----------------------------  ----------"

mapfile -t AGENTS < <(get_agents)
for agent in "${AGENTS[@]}"; do
  role="$(get_agent_field "$agent" "role")"
  model="$(get_agent_field "$agent" "model")"
  lead="$(get_agent_field "$agent" "lead")"
  character="$(get_agent_field "$agent" "character")"
  rules="$(get_agent_field "$agent" "rules")"
  lead_tag=""
  [ "$lead" = "True" ] && lead_tag=" ${YELLOW}(lead)${RESET}"

  echo -en "  ${BOLD}${agent}${RESET}"
  padding=$((17 - ${#agent}))
  printf "%${padding}s" ""
  echo -en "${DIM}${model}${RESET}"
  model_padding=$((31 - ${#model}))
  printf "%${model_padding}s" ""
  echo -e "${role}${lead_tag}"
  echo -e "  ${DIM}  ${character}${RESET}"
  [ -n "$rules" ] && echo -e "  ${CYAN}  Rules: ${rules}${RESET}"

  # Show journal/notes counts
  journal_count="$(find "$COMMS_DIR/$agent/journal" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  notes_count="$(find "$COMMS_DIR/$agent/notes" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  echo -e "  ${DIM}  Journal: ${journal_count} entries | Notes: ${notes_count} files${RESET}"
done

echo ""
echo -e "  ${BOLD}Agents:${RESET}  .opencode/agents/"
echo -e "  ${BOLD}Memory:${RESET}  comms/<name>/journal/ and comms/<name>/notes/"
echo ""
