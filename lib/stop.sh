#!/usr/bin/env bash
# Muster — Stop

SESSION="muster"

root="$(find_comms_root 2>/dev/null)"

# Kill dashboard server by finding the actual process
kill_dashboard() {
  # Try PID file first
  if [ -n "$root" ] && [ -f "$root/.muster-dashboard.pid" ]; then
    kill "$(cat "$root/.muster-dashboard.pid")" 2>/dev/null
    rm -f "$root/.muster-dashboard.pid"
  fi
  # Also kill any python process running our dashboard server
  pkill -f "dashboard/server.py" 2>/dev/null || true
}

# Kill dispatch
kill_dispatch() {
  if [ -n "$root" ] && [ -f "$root/.muster-dispatch.pid" ]; then
    local pid
    pid="$(cat "$root/.muster-dispatch.pid")"
    # Kill the dispatch process and all its children (inotifywait subprocesses)
    kill -- -"$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')" 2>/dev/null || kill "$pid" 2>/dev/null || true
    rm -f "$root/.muster-dispatch.pid"
  fi
  pkill -f "dispatch.sh" 2>/dev/null || true
}

# Kill background processes BEFORE tmux (since stop may be running inside tmux)
kill_dashboard
kill_dispatch

if [ -n "$root" ]; then
  rm -f "$root/.muster-status.sh"
  rm -f "$root/.muster-dashboard-port"
  rm -f "$root/.muster-title.sh"
  rm -rf "$root/.muster-dispatch-state"
fi

# Kill tmux session last — this may kill us too if we're running inside it
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

success "Muster stopped."
