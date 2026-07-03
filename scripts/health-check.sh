#!/bin/sh
set -u

failures=0
warnings=0

pass() {
  printf "PASS  %s\n" "$1"
}

fail() {
  printf "FAIL  %s\n" "$1"
  failures=$((failures + 1))
}

warn() {
  printf "WARN  %s\n" "$1"
  warnings=$((warnings + 1))
}

require_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command available: $1"
  else
    fail "missing required command: $1"
  fi
}

optional_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "optional command available: $1"
  else
    warn "missing optional/manual command: $1"
  fi
}

check_vendor_tool() {
  cmd=$1
  expected_path=$2
  actual_path=$(command -v "$cmd" 2>/dev/null || true)

  if [ -z "$actual_path" ]; then
    fail "missing vendor-managed command: $cmd"
    return
  fi

  if [ "$actual_path" = "$expected_path" ]; then
    pass "vendor-managed command path: $cmd"
  else
    warn "$cmd expected $expected_path, got $actual_path"
  fi
}

check_chezmoi_source() {
  expected_source=$(cd "$(dirname "$0")/.." && pwd)
  actual_source=$(chezmoi source-path 2>/dev/null)

  if [ -z "$actual_source" ]; then
    fail "chezmoi source path could not be read"
    return
  fi

  if [ ! -d "$actual_source" ]; then
    fail "chezmoi source path missing: $actual_source"
    return
  fi

  if [ "$actual_source" = "$expected_source" ]; then
    pass "chezmoi source path points to this repo"
  else
    fail "chezmoi source path expected $expected_source, got $actual_source"
  fi
}

check_default() {
  domain=$1
  key=$2
  expected=$3
  actual=$(defaults read "$domain" "$key" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    pass "$domain $key = $expected"
  else
    fail "$domain $key expected $expected, got ${actual:-<unset>}"
  fi
}

check_app() {
  app_path=$1
  app_name=$(basename "$app_path" .app)
  if [ -d "$app_path" ]; then
    pass "app installed: $app_name"
  else
    warn "app missing/manual: $app_name"
  fi
}

expand_home() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

check_yt_to_gobby() {
  if [ ! -x "$HOME/.local/bin/yt-to-gobby" ]; then
    return
  fi

  zsh_cfg="$HOME/.config/zsh/custom/yt-to-gobby.zsh"
  if [ ! -f "$zsh_cfg" ]; then
    fail "yt-to-gobby installed but missing $zsh_cfg"
    return
  fi

  host=$(
    grep '^export HERMES_YT_HOST=' "$zsh_cfg" 2>/dev/null \
      | sed -E 's/^export HERMES_YT_HOST="([^"]*)".*/\1/' \
      | head -1
  )
  if [ -z "$host" ]; then
    fail "yt-to-gobby enabled but HERMES_YT_HOST is empty; set hermesYtHost in ~/.config/chezmoi/chezmoi.toml"
    return
  fi

  pass "yt-to-gobby HERMES_YT_HOST configured"
}

check_herdr_cwd() {
  config="$HOME/.config/herdr/config.toml"
  if [ ! -f "$config" ]; then
    return
  fi

  new_cwd=$(
    grep -E '^new_cwd[[:space:]]*=' "$config" 2>/dev/null \
      | sed -E 's/^new_cwd[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/' \
      | head -1
  )
  if [ -z "$new_cwd" ]; then
    fail "herdr config missing new_cwd in [terminal]"
    return
  fi

  expanded=$(expand_home "$new_cwd")
  if [ -d "$expanded" ]; then
    pass "herdr new_cwd exists: $new_cwd"
  else
    fail "herdr new_cwd missing on disk: $new_cwd"
  fi
}

echo "Checking required commands..."
for cmd in brew chezmoi git gh rg fd fzf bat eza zoxide starship uv mise node pnpm delta direnv just hyperfine btop dust dua yazi; do
  require_cmd "$cmd"
done

if [ -f /opt/homebrew/share/antidote/antidote.zsh ]; then
  pass "antidote Homebrew script available"
else
  fail "missing required Homebrew antidote script"
fi

check_chezmoi_source

echo
echo "Checking managed app config..."
check_yt_to_gobby
check_herdr_cwd

echo
echo "Checking optional commands..."
for cmd in mas dockutil; do
  optional_cmd "$cmd"
done

echo
echo "Checking vendor-managed commands..."
check_vendor_tool claude "$HOME/.local/bin/claude"

echo
echo "Checking shell startup..."
if zsh -lic 'echo shell ok' >/dev/null 2>&1; then
  pass "zsh interactive login shell starts"
else
  fail "zsh interactive login shell failed"
fi

echo
echo "Checking selected macOS defaults..."
check_default com.apple.dock orientation left
check_default com.apple.dock autohide 1
check_default com.apple.dock tilesize 41
check_default NSGlobalDomain ApplePressAndHoldEnabled 0
check_default NSGlobalDomain KeyRepeat 2
check_default NSGlobalDomain InitialKeyRepeat 15
check_default com.apple.finder ShowPathbar 1

echo
echo "Checking selected apps..."
check_app "/Applications/Google Chrome.app"
check_app "/Applications/Cursor.app"
check_app "/Applications/Visual Studio Code.app"
check_app "/Applications/Ghostty.app"
check_app "/Applications/iTerm.app"
check_app "/Applications/Raycast.app"
check_app "/Applications/Notion.app"
check_app "/Applications/Slack.app"
check_app "/Applications/Obsidian.app"
check_app "/Applications/OrbStack.app"

echo
echo "Health check complete: $failures failure(s), $warnings warning(s)."

if [ "$failures" -gt 0 ]; then
  exit 1
fi

exit 0
