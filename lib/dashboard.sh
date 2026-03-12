#!/usr/bin/env bash
# Muster — Launch dashboard

root="$(find_comms_root)" || die "No muster project found. Run 'muster init' first."

PORT="${1:-4200}"

info "Starting muster dashboard on http://localhost:$PORT"

python3 "$MUSTER_ROOT/dashboard/server.py" "$PORT"
