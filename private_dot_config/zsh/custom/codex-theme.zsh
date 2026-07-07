# codex: auto-pick the TUI syntax-highlighting theme from the macOS
# light/dark appearance, mirroring Ghostty's dark:/light: theme split.
#
# Codex has no native "auto" theme (the [tui] theme in ~/.codex/config.toml is
# a fixed name, read once at launch), so this wrapper detects the current
# appearance and injects `-c tui.theme=...` each time codex starts. The value
# in config.toml stays as the fallback for launches that bypass this function.
#
# Override the pair per-machine with CODEX_LIGHT_THEME / CODEX_DARK_THEME.
codex() {
  local -a theme_args
  # Skip if not macOS, or if the caller already set their own theme override.
  if [[ "$OSTYPE" == darwin* ]] && [[ "$*" != *tui.theme* ]]; then
    local light="${CODEX_LIGHT_THEME:-one-half-light}"
    local dark="${CODEX_DARK_THEME:-one-half-dark}"
    # `defaults read -g AppleInterfaceStyle` prints "Dark" in dark mode and
    # errors (domain does not exist) in light mode.
    if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi dark; then
      theme_args=(-c "tui.theme=\"$dark\"")
    else
      theme_args=(-c "tui.theme=\"$light\"")
    fi
  fi
  command codex "${theme_args[@]}" "$@"
}
