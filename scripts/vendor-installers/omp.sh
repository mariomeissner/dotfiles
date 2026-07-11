#!/bin/sh
set -eu

OMP="$HOME/.local/bin/omp"

if [ -x "$OMP" ]; then
  echo "OMP already installed: $("$OMP" --version)"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not available; skipping OMP install."
  exit 0
fi

echo "Installing OMP via its official binary installer..."

# Force the prebuilt binary path so installation does not vary based on whether
# Bun happens to be present on a machine. OMP's installer only warns about PATH;
# it does not edit shell startup files.
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT HUP INT TERM
curl -fsSL https://omp.sh/install -o "$INSTALLER"
PI_INSTALL_DIR="$HOME/.local/bin" sh "$INSTALLER" --binary
