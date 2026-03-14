#!/usr/bin/env bash
# Muster — Reset (nuke everything and start over)

root="$(find_comms_root)" || die "No muster project found."

COMMS_DIR="$root/comms"
AGENTS_DIR="$root/.opencode/agents"

echo ""
warn "This will delete comms/ (team config + all agent journals/notes) and .opencode/agents/."
read -rp "Are you sure? [y/N]: " confirm
confirm="$(echo "${confirm:-n}" | tr '[:upper:]' '[:lower:]')"
[ "$confirm" != "y" ] && die "Cancelled."

rm -rf "$COMMS_DIR"
rm -rf "$AGENTS_DIR"
success "Cleared. Run 'muster init' to start fresh."
echo ""
