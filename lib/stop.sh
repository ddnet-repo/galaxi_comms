#!/usr/bin/env bash
# Muster — Stop

SESSION="muster"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  root="$(find_comms_root 2>/dev/null)" && rm -f "$root/.muster-status.sh"
  success "Muster stopped."
else
  warn "No muster session running."
fi
