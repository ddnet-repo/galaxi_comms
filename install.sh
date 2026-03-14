#!/usr/bin/env bash
set -euo pipefail

REPO="ddnet-repo/muster"
INSTALL_DIR="$HOME/.muster"
BIN_LINK="/usr/local/bin/muster"

echo ""
echo "Installing muster..."
echo ""

# Check deps
missing=()
command -v python3 &>/dev/null || missing+=("python3")

if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing dependencies: ${missing[*]}"
  echo ""
  echo "  Linux:  sudo apt install python3"
  echo "  macOS:  brew install python3"
  echo ""
  exit 1
fi

# Clean previous install
rm -rf "$INSTALL_DIR"

# Clone
if command -v git &>/dev/null; then
  git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR" 2>/dev/null
else
  echo "git not found. Install git and try again."
  exit 1
fi

# Symlink
chmod +x "$INSTALL_DIR/bin/muster"

if [ -w "$(dirname "$BIN_LINK")" ]; then
  ln -sf "$INSTALL_DIR/bin/muster" "$BIN_LINK"
else
  echo "Need sudo to symlink to $BIN_LINK"
  sudo ln -sf "$INSTALL_DIR/bin/muster" "$BIN_LINK"
fi

echo ""
echo "Installed muster to $INSTALL_DIR"
echo "Command available at: $BIN_LINK"
echo ""
echo "Run 'muster init' in any project to get started."
echo ""
