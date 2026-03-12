#!/usr/bin/env bash
# Muster — Inbox Dispatch + Agent Monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

root="$(find_comms_root)" || die "No muster project found."
COMMS_DIR="$root/comms"
mapfile -t AGENTS < <(get_agents)

watcher="$(detect_watcher)"
if [ "$watcher" = "none" ]; then
  die "No file watcher found. Install inotify-tools (Linux) or fswatch (macOS)."
fi

SESSION="muster"
NAG_COOLDOWN=300       # Don't nag same agent more than once per 5 min
IDLE_THRESHOLD=180     # 3 minutes of pane inactivity before we care
CHECK_INTERVAL=60      # Check every 60 seconds

# State tracking directory
STATE_DIR="$root/.muster-dispatch-state"
mkdir -p "$STATE_DIR"

info "Watching ${#AGENTS[@]} inboxes..."

# --- Inbox watchers (instant notification on new mail) ---

for agent in "${AGENTS[@]}"; do
  inbox="$COMMS_DIR/$agent/inbox"
  mkdir -p "$inbox"

  if [ "$watcher" = "inotify" ]; then
    (
      last_notify=0
      inotifywait -m -q --format '%f' -e create "$inbox" 2>/dev/null |
      while read -r filename; do
        case "$filename" in
          *.md)
            now=$(date +%s)
            if [ $((now - last_notify)) -ge 2 ]; then
              tmux send-keys -t "$SESSION:$agent" "You have new mail. Check your inbox." Enter 2>/dev/null || true
              last_notify=$now
            fi
            ;;
        esac
      done
    ) &
  else
    (
      last_notify=0
      fswatch --event Created -r "$inbox" 2>/dev/null |
      while read -r filepath; do
        case "$filepath" in
          *.md)
            now=$(date +%s)
            if [ $((now - last_notify)) -ge 2 ]; then
              tmux send-keys -t "$SESSION:$agent" "You have new mail. Check your inbox." Enter 2>/dev/null || true
              last_notify=$now
            fi
            ;;
        esac
      done
    ) &
  fi

  # Initialize state tracking
  echo "0" > "$STATE_DIR/${agent}.last_nag"
  echo "" > "$STATE_DIR/${agent}.last_pane"

  echo "  Watching $agent"
done

echo ""
info "All inboxes monitored. Starting agent monitor."

# --- Helper: check if pane looks idle ---

get_pane_last_line() {
  local agent="$1"
  tmux capture-pane -t "$SESSION:$agent" -p 2>/dev/null | tail -10 |
    sed 's/\x1b\[[0-9;]*m//g' |
    grep -v '^[[:space:]]*$' |
    tail -1 || echo ""
}

is_pane_idle() {
  local agent="$1"
  local current_line
  current_line="$(get_pane_last_line "$agent")"
  local prev_line
  prev_line="$(cat "$STATE_DIR/${agent}.last_pane" 2>/dev/null || echo "")"

  echo "$current_line" > "$STATE_DIR/${agent}.last_pane"

  if [ "$current_line" = "$prev_line" ]; then
    # Pane hasn't changed — increment idle counter
    local idle_count
    idle_count="$(cat "$STATE_DIR/${agent}.idle_count" 2>/dev/null || echo "0")"
    idle_count=$((idle_count + 1))
    echo "$idle_count" > "$STATE_DIR/${agent}.idle_count"
    local idle_seconds=$((idle_count * CHECK_INTERVAL))
    [ "$idle_seconds" -ge "$IDLE_THRESHOLD" ] && return 0
    return 1
  else
    # Pane changed — reset idle counter
    echo "0" > "$STATE_DIR/${agent}.idle_count"
    return 1
  fi
}

can_nag() {
  local agent="$1"
  local now
  now="$(date +%s)"
  local last_nag
  last_nag="$(cat "$STATE_DIR/${agent}.last_nag" 2>/dev/null || echo "0")"
  [ $((now - last_nag)) -ge "$NAG_COOLDOWN" ] && return 0
  return 1
}

record_nag() {
  local agent="$1"
  date +%s > "$STATE_DIR/${agent}.last_nag"
}

send_nag() {
  local agent="$1" message="$2"
  tmux send-keys -t "$SESSION:$agent" "NUDGE: $message" Enter 2>/dev/null || true
  record_nag "$agent"
}

# --- Periodic monitor loop ---

(
  # Let agents boot before we start monitoring
  sleep 30

  while true; do
    # Sprint done? Board empty + all agents clear → stop monitoring
    board_count="$(count_md "$COMMS_DIR/board")"
    all_done=true
    for agent in "${AGENTS[@]}"; do
      ic="$(count_md "$COMMS_DIR/$agent/inbox")"
      ac="$(count_md "$COMMS_DIR/$agent/active")"
      if [ "$ic" -gt 0 ] || [ "$ac" -gt 0 ]; then
        all_done=false
        break
      fi
    done
    if [ "$board_count" -eq 0 ] && [ "$all_done" = true ]; then
      break
    fi

    for agent in "${AGENTS[@]}"; do
      inbox_count="$(count_md "$COMMS_DIR/$agent/inbox")"
      active_count="$(count_md "$COMMS_DIR/$agent/active")"

      # Agent is done — board clear, nothing active, inbox empty. Leave them alone.
      if [ "$inbox_count" -eq 0 ] && [ "$active_count" -eq 0 ]; then
        continue
      fi

      # Skip if we nagged recently
      can_nag "$agent" || continue

      # Check if pane is idle
      pane_idle=false
      is_pane_idle "$agent" && pane_idle=true

      # Rule 1: Has mail, nothing in active, and idle → pick something up
      if [ "$inbox_count" -gt 0 ] && [ "$active_count" -eq 0 ] && [ "$pane_idle" = true ]; then
        send_nag "$agent" "You have $inbox_count unread message(s) in your inbox and nothing in active/. Check your mail and pick up work."
        continue
      fi

      # Rule 2: Has active work but pane is idle → are you stuck?
      if [ "$active_count" -gt 0 ] && [ "$pane_idle" = true ]; then
        send_nag "$agent" "You have $active_count item(s) in active/ but you seem idle. If you're blocked, tell the lead. If you're done, move them to archive/."
        continue
      fi

      # Rule 3: Workspace hygiene — too much stuff piling up
      nag=""
      if [ "$inbox_count" -gt 3 ]; then
        nag="You have $inbox_count items in your inbox. Read them, then move to archive/ or trash/."
      fi
      if [ "$active_count" -gt 3 ]; then
        nag="${nag:+$nag }You have $active_count items in active/. Max is 3. Finish, archive, or trash."
      fi
      if [ -n "$nag" ]; then
        send_nag "$agent" "$nag"
      fi
    done

    sleep "$CHECK_INTERVAL"
  done
) &

wait
