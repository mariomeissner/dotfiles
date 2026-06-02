#!/bin/sh
set -eu

CLAUDE="$HOME/.local/bin/claude"

if [ -x "$CLAUDE" ]; then
  echo "Claude Code already installed: $("$CLAUDE" --version)"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not available; skipping Claude Code install."
  exit 0
fi

echo "Installing Claude Code via Anthropic native installer..."
curl -fsSL https://claude.ai/install.sh | bash -s latest
