#!/bin/sh
set -eu

# Ensure Homebrew-installed tools are on PATH (e.g. on first apply, when the
# running shell predates the Homebrew install).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

restart_dock() {
  uid=$(id -u)
  service="gui/$uid/com.apple.Dock.agent"

  killall Dock >/dev/null 2>&1 || true

  i=0
  while [ "$i" -lt 20 ]; do
    if launchctl print "$service" 2>/dev/null | grep -q "state = running"; then
      return 0
    fi
    i=$((i + 1))
    sleep 0.25
  done

  echo "Dock did not restart automatically; kickstarting $service..."
  launchctl kickstart -k "$service" >/dev/null 2>&1 || true

  i=0
  while [ "$i" -lt 20 ]; do
    if launchctl print "$service" 2>/dev/null | grep -q "state = running"; then
      return 0
    fi
    i=$((i + 1))
    sleep 0.25
  done

  echo "Warning: Dock still does not appear to be running."
}

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not installed; skipping Dock item setup."
  exit 0
fi

add_app() {
  app_path=$1
  if [ ! -d "$app_path" ]; then
    echo "Skipping missing app: $app_path"
    return 0
  fi

  app_name=$(basename "$app_path" .app)
  if dockutil --list | grep -F "$app_name" >/dev/null 2>&1; then
    echo "Dock already has: $app_name"
    return 0
  fi

  echo "Adding to Dock: $app_name"
  dockutil --no-restart --add "$app_path" >/dev/null || true
}

echo "Adding Dock essentials without removing or reordering existing items..."

add_app "/Applications/Google Chrome.app"
add_app "/Applications/Cursor.app"
add_app "/Applications/Visual Studio Code.app"
add_app "/Applications/Ghostty.app"
add_app "/Applications/iTerm.app"
add_app "/Applications/Raycast.app"
add_app "/Applications/Notion.app"
add_app "/Applications/Slack.app"
add_app "/Applications/Obsidian.app"

restart_dock
echo "Dock item setup complete."
