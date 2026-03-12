#!/usr/bin/env bash
# Muster — Launch dashboard

root="$(find_comms_root)" || die "No muster project found. Run 'muster init' first."

PORT="${1:-4200}"

# Check if dashboard is already running
if [ -f "$root/.muster-dashboard-port" ]; then
  existing_port="$(cat "$root/.muster-dashboard-port")"
  if [ -f "$root/.muster-dashboard.pid" ]; then
    pid="$(cat "$root/.muster-dashboard.pid")"
    if kill -0 "$pid" 2>/dev/null; then
      echo ""
      info "Dashboard already running at ${CYAN}http://localhost:${existing_port}${RESET}"
      echo ""
      exit 0
    fi
  fi
fi

info "Starting muster dashboard on http://localhost:$PORT"

python3 "$MUSTER_ROOT/dashboard/server.py" "$PORT"
