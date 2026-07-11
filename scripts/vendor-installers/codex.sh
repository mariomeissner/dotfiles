#!/bin/sh
set -eu

CODEX="$HOME/.local/bin/codex"

if [ -x "$CODEX" ]; then
  echo "Codex CLI already installed: $("$CODEX" --version)"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not available; skipping Codex CLI install."
  exit 0
fi

echo "Installing Codex CLI via OpenAI's official installer..."

# Keep the installer focused on the standalone CLI. In particular, hide
# application-bundled Codex copies from its conflict detector: when it sees the
# ChatGPT app's bundled binary, it appends its own block to ~/.zprofile even
# though ~/.local/bin is already on PATH and managed by this repo.
INSTALL_PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT HUP INT TERM
curl -fsSL https://chatgpt.com/codex/install.sh -o "$INSTALLER"
env \
  CODEX_INSTALL_DIR="$HOME/.local/bin" \
  CODEX_NON_INTERACTIVE=true \
  PATH="$INSTALL_PATH" \
  sh "$INSTALLER"
