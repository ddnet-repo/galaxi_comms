#!/usr/bin/env bash
# Muster — Quick status

root="$(find_comms_root)" || die "No muster project found."

COMMS_DIR="$root/comms"
mapfile -t AGENTS < <(get_agents)

echo ""
printf "  ${BOLD}%-16s %-10s %-10s %s${RESET}\n" "AGENT" "INBOX" "ACTIVE" "ROLE"
printf "  %-16s %-10s %-10s %s\n" "----------------" "----------" "----------" "----------"

for agent in "${AGENTS[@]}"; do
  role="$(get_agent_field "$agent" "role")"
  inbox_count="$(count_md "$COMMS_DIR/$agent/inbox")"
  active_count="$(count_md "$COMMS_DIR/$agent/active")"

  if [ "$inbox_count" -gt 0 ]; then
    inbox_display="${YELLOW}${inbox_count}${RESET}"
  else
    inbox_display="${GREEN}${inbox_count}${RESET}"
  fi

  if [ "$active_count" -gt 0 ]; then
    active_display="${CYAN}${active_count}${RESET}"
  else
    active_display="${GREEN}${active_count}${RESET}"
  fi

  printf "  %-16s " "$agent"
  printf "$inbox_display"
  printf "          "
  printf "$active_display"
  printf "          "
  printf "%s" "$role"
  printf "\n"
done

board_count="$(count_md "$COMMS_DIR/board")"
echo ""
echo -e "  ${BOLD}Board:${RESET} $board_count task file(s)"
echo ""
