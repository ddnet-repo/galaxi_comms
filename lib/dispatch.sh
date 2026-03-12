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
      inotifywait -m -r -e create -e modify "$inbox" 2>/dev/null |
      while read; do
        tmux send-keys -t "muster:$agent" "You have new mail in your inbox. Check comms/$agent/inbox/ now." Enter 2>/dev/null || true
      done
    ) &
  else
    (
      fswatch -r "$inbox" 2>/dev/null |
      while read; do
        tmux send-keys -t "muster:$agent" "You have new mail in your inbox. Check comms/$agent/inbox/ now." Enter 2>/dev/null || true
      done
    ) &
  fi

  echo "  Watching $agent"
done

echo ""
info "All inboxes monitored. Ctrl+C to stop."
wait
