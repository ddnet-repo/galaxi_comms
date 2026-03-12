#!/usr/bin/env bash
# Muster — Reset (nuke comms and start over)

root="$(find_comms_root)" || die "No muster project found."

COMMS_DIR="$root/comms"

echo ""
warn "This will delete everything in comms/ — team config, all agent data, board, docs."
read -rp "Are you sure? [y/N]: " confirm
confirm="$(echo "${confirm:-n}" | tr '[:upper:]' '[:lower:]')"
[ "$confirm" != "y" ] && die "Cancelled."

rm -rf "$COMMS_DIR"
success "Cleared. Run 'muster init' to start fresh."
echo ""
