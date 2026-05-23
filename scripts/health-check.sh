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

echo "Checking required commands..."
for cmd in brew chezmoi git gh rg fd fzf bat eza zoxide starship antidote uv mise node pnpm; do
  require_cmd "$cmd"
done

echo
echo "Checking optional commands..."
for cmd in mas dockutil; do
  optional_cmd "$cmd"
done

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
