#!/bin/sh
set -eu

HERDR="$HOME/.local/bin/herdr"

if [ -x "$HERDR" ]; then
  echo "Herdr already installed: $("$HERDR" --version)"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not available; skipping Herdr install."
  exit 0
fi

echo "Installing Herdr via its official installer..."
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT HUP INT TERM
curl -fsSL https://herdr.dev/install.sh -o "$INSTALLER"
HERDR_INSTALL_DIR="$HOME/.local/bin" sh "$INSTALLER"
