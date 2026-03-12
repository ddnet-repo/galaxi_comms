#!/usr/bin/env bash
# Muster — Upgrade to latest version

current="$MUSTER_VERSION"

info "Upgrading muster..."

if ! command -v git &>/dev/null; then
  die "git not found. Can't upgrade."
fi

if [ ! -d "$MUSTER_ROOT/.git" ]; then
  die "Muster install is not a git repo. Reinstall with the curl script."
fi

git -C "$MUSTER_ROOT" pull --ff-only origin master 2>/dev/null || die "Upgrade failed. Try reinstalling with the curl script."

# Reload version
new="$(grep 'MUSTER_VERSION=' "$MUSTER_ROOT/lib/common.sh" | sed 's/.*"\(.*\)"/\1/')"

if [ "$current" = "$new" ]; then
  success "Already on latest: $current"
else
  success "Upgraded: $current -> $new"
fi
