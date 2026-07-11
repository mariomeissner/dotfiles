#!/bin/sh
set -eu

GROK="$HOME/.local/bin/grok"

if [ -x "$GROK" ]; then
  echo "Grok CLI already installed: $("$GROK" --version)"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not available; skipping Grok CLI install."
  exit 0
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "bash is not available; skipping Grok CLI install."
  exit 0
fi

echo "Installing Grok CLI via xAI's official installer..."

# Grok has no no-shell-config flag. It chooses which startup file to edit only
# from $SHELL, so use a neutral value and install directly into the PATH already
# managed by this repo.
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT HUP INT TERM
curl -fsSL https://x.ai/cli/install.sh -o "$INSTALLER"
env \
  GROK_BIN_DIR="$HOME/.local/bin" \
  SHELL=/bin/false \
  bash "$INSTALLER"
