#!/bin/sh
set -eu

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

killall Dock >/dev/null 2>&1 || true
echo "Dock item setup complete."

