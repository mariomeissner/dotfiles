#!/bin/sh
set -eu

force=false
if [ "${1:-}" = "--force" ]; then
  force=true
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: sh scripts/seed-claude.sh [--force]

Seed Claude Code preferences on a new machine.

Copies the authored, version-controlled content from scripts/seed-claude/
(CLAUDE.md and statusline.sh) into ~/.claude, and writes a baseline
settings.json, plus an empty CLAUDE.local.md for machine-specific notes. It
does NOT set a model or manage Herdr-generated files.

Default behavior is conservative: create missing files and skip existing files.
With --force, existing files are backed up next to the original (.backup-<ts>)
before being replaced. Rerun with --force after editing a payload file in the
repo to resync it onto this machine.

After Herdr updates, install its generated integration files with:
  herdr integration install claude
EOF
  exit 0
elif [ -n "${1:-}" ]; then
  echo "unknown argument: $1" >&2
  exit 2
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
payload_dir="$script_dir/seed-claude"
if [ ! -d "$payload_dir" ]; then
  echo "payload directory not found: $payload_dir" >&2
  exit 1
fi

backup_path() {
  target="$1"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  echo "$target.backup-$timestamp"
}

# Back up an existing target when --force; returns 1 (skip) when the target
# exists and --force was not given.
guard_target() {
  target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    if [ "$force" != true ]; then
      echo "skip existing $target"
      return 1
    fi
    backup="$(backup_path "$target")"
    cp -p "$target" "$backup"
    echo "backed up $target to $backup"
  fi
  return 0
}

# Write stdin to a target with the given mode (used for generated settings.json).
write_file() {
  target="$1"
  mode="$2"
  guard_target "$target" || return 0
  tmp="$target.tmp.$$"
  cat >"$tmp"
  chmod "$mode" "$tmp"
  mv "$tmp" "$target"
  echo "wrote $target"
}

# Write stdin to a target only if it does not exist. Machine-owned files use
# this so re-seeding (even with --force) never clobbers local edits.
write_if_missing() {
  target="$1"
  mode="$2"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    echo "keep existing $target"
    return 0
  fi
  tmp="$target.tmp.$$"
  cat >"$tmp"
  chmod "$mode" "$tmp"
  mv "$tmp" "$target"
  echo "wrote $target"
}

# Copy a payload file to a target with the given mode.
copy_file() {
  src="$1"
  target="$2"
  mode="$3"
  guard_target "$target" || return 0
  tmp="$target.tmp.$$"
  cp "$src" "$tmp"
  chmod "$mode" "$tmp"
  mv "$tmp" "$target"
  echo "wrote $target"
}

# Baseline settings. Intentionally omits "model" so a new machine keeps Claude
# Code's own default; set the model per-machine afterwards.
write_file "$HOME/.claude/settings.json" 600 <<EOF
{
  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "300000",
    "BASH_MAX_TIMEOUT_MS": "3600000"
  },
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch",
      "Bash(pnpm typecheck *)",
      "Bash(git init *)",
      "Bash(git add *)"
    ],
    "defaultMode": "auto"
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash '${HOME}/.claude/hooks/herdr-agent-state.sh' session",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 1
  },
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "enableWorkflows": true,
  "effortLevel": "high",
  "autoMemoryEnabled": false,
  "skipDangerousModePermissionPrompt": true,
  "skipAutoPermissionPrompt": true,
  "skipWorkflowUsageWarning": true,
  "theme": "auto",
  "preferredNotifChannel": "ghostty",
  "switchModelsOnFlag": false,
  "autoCompactEnabled": false,
  "tui": "fullscreen"
}
EOF

# Authored content from the tracked payload, copied verbatim.
copy_file "$payload_dir/CLAUDE.md" "$HOME/.claude/CLAUDE.md" 600
copy_file "$payload_dir/statusline.sh" "$HOME/.claude/statusline.sh" 755

# Machine-specific preferences, imported by the shared CLAUDE.md via
# "@CLAUDE.local.md". Seeded empty and never overwritten, so each machine owns
# its own content; add whatever this machine needs after seeding.
write_if_missing "$HOME/.claude/CLAUDE.local.md" 600 <<'EOF'
# This machine
EOF

echo "Claude seed complete."
