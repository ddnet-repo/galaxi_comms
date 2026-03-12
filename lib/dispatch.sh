#!/usr/bin/env bash
# Muster — Inbox Dispatch (cross-platform)
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

info "Watching ${#AGENTS[@]} inboxes..."

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
              tmux send-keys -t "muster:$agent" "You have new mail. Check your inbox." Enter 2>/dev/null || true
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
              tmux send-keys -t "muster:$agent" "You have new mail. Check your inbox." Enter 2>/dev/null || true
              last_notify=$now
            fi
            ;;
        esac
      done
    ) &
  fi

  echo "  Watching $agent"
done

echo ""
info "All inboxes monitored."

# Periodic workspace nag — check every 5 minutes
(
  while true; do
    sleep 300
    for agent in "${AGENTS[@]}"; do
      inbox_count="$(count_md "$COMMS_DIR/$agent/inbox")"
      active_count="$(count_md "$COMMS_DIR/$agent/active")"

      nag=""
      if [ "$inbox_count" -gt 3 ]; then
        nag="You have $inbox_count items in your inbox. Read them, then move them to archive/ or trash/."
      fi
      if [ "$active_count" -gt 3 ]; then
        nag="${nag:+$nag }You have $active_count items in active/. Max is 3. Finish, archive, or trash the rest."
      fi

      if [ -n "$nag" ]; then
        tmux send-keys -t "muster:$agent" "NUDGE: $nag" Enter 2>/dev/null || true
      fi
    done
  done
) &

wait
