#!/bin/sh
set -eu

force=false
if [ "${1:-}" = "--force" ]; then
  force=true
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: sh scripts/seed-claude.sh [--force]

Seed Claude Code preferences on a new machine.

Default behavior is conservative: create missing files and skip existing files.
With --force, existing files are backed up next to the original before being
replaced.

After Herdr updates, run:
  herdr integration install claude
EOF
  exit 0
elif [ -n "${1:-}" ]; then
  echo "unknown argument: $1" >&2
  exit 2
fi

backup_path() {
  target="$1"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  echo "$target.backup-$timestamp"
}

write_file() {
  target="$1"
  mode="$2"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    if [ "$force" != true ]; then
      echo "skip existing $target"
      return 0
    fi
    backup="$(backup_path "$target")"
    cp -p "$target" "$backup"
    echo "backed up $target to $backup"
  fi
  tmp="$target.tmp.$$"
  cat >"$tmp"
  chmod "$mode" "$tmp"
  mv "$tmp" "$target"
  echo "wrote $target"
}

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
  "model": "claude-fable-5[1m]",
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

write_file "$HOME/.claude/CLAUDE.md" 600 <<EOF
# User preferences

## Timezone - always JST

Mario is in Japan. Always present timestamps in JST (Asia/Tokyo, UTC+9).

- Convert UTC timestamps to JST and label the conversion.
- When a source's timezone is ambiguous, state the assumption and offer to confirm.

## Git commits - author is always Mario

- Commit author is always \`$(git config --global user.email 2>/dev/null || echo "jmariomeissner@gmail.com")\`.
- Never append AI co-author or attribution trailers to commit messages.

## Local repos - verify freshness when remote state matters

When the answer depends on current remote state, run \`git fetch\` first and
compare against \`origin\`. If a repo cannot be fetched, say so explicitly.

## Codex second opinions

The Codex CLI can be used as an independent read-only second opinion for hard
bugs, subtle design decisions, and adversarial diff review.
EOF

write_file "$HOME/.claude/statusline.sh" 755 <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
ESC=$'\033'

cwd=$(jq -rn --argjson d "$input" '$d.workspace.current_dir // $d.cwd // ""')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
fi

jq -rn --argjson d "$input" --arg branch "$branch" --arg E "$ESC" '
  def color(c; s): $E + "[" + c + "m" + s + $E + "[0m";
  def k: if . >= 1000 then ((./1000)|floor|tostring) + "k" else (.|tostring) end;
  def meter(p; s): if p >= 90 then color("31"; s) elif p >= 70 then color("33"; s) else s end;
  ($d.model.display_name // "?") as $model |
  ($d.effort.level // "") as $eff |
  ($d.context_window.total_input_tokens // 0) as $used |
  ($d.context_window.context_window_size // 0) as $max |
  ($d.context_window.used_percentage // 0) as $pct |
  [
    color("36"; $model) + (if $eff != "" then color("90"; " - " + $eff) else "" end),
    (if $branch != "" then ("git:" + $branch) else empty end),
    (if $max > 0 then meter($pct; "ctx " + ($used|k) + "/" + ($max|k)) else empty end)
  ] | map(select(. != "" and . != null)) | join(color("90"; "  -  "))
'
EOF

write_file "$HOME/.claude/skills/oracle/SKILL.md" 644 <<'EOF'
---
name: oracle
description: Consult OpenAI Codex as an independent second-opinion oracle for stuck bugs, subtle design decisions, or adversarial diff review.
---

# oracle

Run `codex exec` headless against the relevant repo. Codex reads the code
itself, so give it pointers, not pasted dumps.

```bash
codex exec --ephemeral --sandbox read-only --color never \
  -c model_reasoning_effort=high \
  -C <git-repo-root> \
  -o <scratchpad>/oracle-answer.md \
  "$(cat <<'PROMPT'
<self-contained brief>
PROMPT
)" </dev/null
```

Include the goal, precise question, relevant `path:line` pointers, what has
been tried, and constraints. Treat the answer as advisory and verify concrete
claims before acting.
EOF

echo "Claude seed complete."
