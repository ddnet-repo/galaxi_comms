#!/usr/bin/env bash
# Muster — Stop

SESSION="muster"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  root="$(find_comms_root 2>/dev/null)"
  if [ -n "$root" ]; then
    rm -f "$root/.muster-status.sh"
    if [ -f "$root/.muster-dispatch.pid" ]; then
      kill "$(cat "$root/.muster-dispatch.pid")" 2>/dev/null
      rm -f "$root/.muster-dispatch.pid"
    fi
  fi
  success "Muster stopped."
else
  warn "No muster session running."
fi
