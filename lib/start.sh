#!/usr/bin/env bash
# Muster — Start all agent sessions in tmux

check_deps

root="$(find_comms_root)" || die "No muster project found. Run 'muster init' first."

COMMS_DIR="$root/comms"
TEAM_JSON="$COMMS_DIR/team.json"
PROJECT="$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['project'])")"
AGENT_CLI="$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['agent_cli'])")"
command -v "$AGENT_CLI" &>/dev/null || die "$AGENT_CLI not found. Install it or update agent_cli in comms/team.json."
SESSION="muster"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Read agents
mapfile -t AGENTS < <(get_agents)

if [ ${#AGENTS[@]} -eq 0 ]; then
  die "No agents found in team.json."
fi

# Build tmux status bar script
STATUS_SCRIPT="$root/.muster-status.sh"
cat > "$STATUS_SCRIPT" <<'STATUSEOF'
#!/usr/bin/env bash
COMMS_DIR="COMMS_PLACEHOLDER"
AGENTS_STR="AGENTS_PLACEHOLDER"
IFS=',' read -ra AGENTS <<< "$AGENTS_STR"
out=""
for agent in "${AGENTS[@]}"; do
  inbox_dir="$COMMS_DIR/$agent/inbox"
  count=0
  [ -d "$inbox_dir" ] && count=$(find "$inbox_dir" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    out+=" #[fg=yellow,bold]${agent}:${count}#[default] "
  else
    out+=" ${agent}:${count} "
  fi
done
echo "$out"
STATUSEOF

# Fill in placeholders
sed -i "s|COMMS_PLACEHOLDER|$COMMS_DIR|g" "$STATUS_SCRIPT"
agents_csv="$(IFS=,; echo "${AGENTS[*]}")"
sed -i "s|AGENTS_PLACEHOLDER|$agents_csv|g" "$STATUS_SCRIPT"
chmod +x "$STATUS_SCRIPT"

# Launch an agent in a tmux window
launch_agent() {
  local agent="$1" create_session="${2:-}"
  local model
  model="$(get_agent_field "$agent" "model")"
  local cli_cmd="$AGENT_CLI"
  [ -n "$model" ] && cli_cmd="$AGENT_CLI --model $model"

  if [ "$create_session" = "new" ]; then
    tmux new-session -d -s "$SESSION" -n "$agent" -c "$root"
  else
    tmux new-window -t "$SESSION" -n "$agent" -c "$root"
  fi
  tmux send-keys -t "$SESSION:$agent" "$cli_cmd; tmux kill-session -t $SESSION" Enter
}

# Create the tmux session with monitor as window 0
tmux new-session -d -s "$SESSION" -n "monitor" -c "$root"
tmux send-keys -t "$SESSION:monitor" "watch -n 5 '$MUSTER_ROOT/bin/muster status'" Enter

# Create agent windows
for agent in "${AGENTS[@]}"; do
  launch_agent "$agent"
done

# Wait for all agents to boot
info "Waiting for agents to start..."
sleep 8

# Send initial prompts
for agent in "${AGENTS[@]}"; do
  tmux send-keys -t "$SESSION:$agent" "You are $agent. Read your profile at comms/$agent/profile.md and begin." Enter
done

# Run dispatch in the background (no window)
"$LIB/dispatch.sh" &
echo $! > "$root/.muster-dispatch.pid"

# Keybind: Ctrl+b Q kills the whole muster session
tmux bind-key -T prefix Q run-shell "'$MUSTER_ROOT/bin/muster' stop"

# Configure status bar
tmux set-option -t "$SESSION" status-right "#($STATUS_SCRIPT)"
tmux set-option -t "$SESSION" status-interval 5
tmux set-option -t "$SESSION" status-right-length 120
tmux set-option -t "$SESSION" status-style "bg=black,fg=white"
tmux set-option -t "$SESSION" window-status-current-style "bg=blue,fg=white,bold"

# Jump to monitor (window 0)
tmux select-window -t "$SESSION:monitor"

echo ""
success "Muster launched: $SESSION"
echo -e "${DIM}${#AGENTS[@]} agents + monitor + dispatch${RESET}"
echo -e "${DIM}Ctrl+b Q to kill the session${RESET}"
echo -e "${DIM}Ctrl+b n/p to switch agents${RESET}"
echo ""

# Attach
tmux attach -t "$SESSION"
