# Dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

These dotfiles are public for transparency and portability, but they are tuned
for my own machines. Review the source before applying it elsewhere.

The setup favors explicit, reviewable changes: inspect drift with `chezmoi diff`,
then apply intentionally.

## What This Manages

- Homebrew formulae and casks via `Brewfile`
- zsh login and interactive shell setup
- Git identity and default behavior
- SSH client defaults for GitHub and local overrides
- zsh plugins via Antidote
- Starship prompt configuration
- Node LTS via `mise`
- Python tooling via `uv`
- Ghostty and cmux terminal appearance
- Selected macOS defaults
- Dock setup
- A small set of personal helper scripts
- Karabiner-Elements JIS→ANSI remaps (opt-in via `enableKarabiner`)

## Quick Start

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply mariomeissner/dotfiles
```

On an existing machine, preview first:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init mariomeissner/dotfiles
chezmoi diff
chezmoi apply
```

## Normal Workflow

Edit dotfiles in the source repo:

```sh
chezmoi cd
```

Preview changes:

```sh
chezmoi diff
```

Apply changes:

```sh
chezmoi apply
```

Update an existing machine from the repo:

```sh
chezmoi update
```

If an app or manual edit changes a live file, preview the drift before importing
it into the repo:

```sh
chezmoi diff ~/.zprofile
chezmoi add --dry-run --verbose ~/.zprofile
chezmoi add ~/.zprofile
chezmoi cd
git diff -- dot_zprofile
```

If `chezmoi diff` shows a manual change you care about, stop and reconcile it.
Either incorporate it into the source repo, make it intentionally local/private,
or decide to discard it.

## Repository Layout

- `Brewfile`: Homebrew CLI tools and apps.
- `dot_gitconfig.tmpl`: Git identity and default behavior.
- `private_dot_ssh/private_config`: SSH client defaults.
- `dot_zprofile`: login-shell Homebrew and environment setup.
- `dot_zshrc`: interactive zsh setup.
- `dot_zsh_plugins.txt`: Antidote plugin list.
- `private_dot_config/`: managed files under `~/.config/`.
- `dot_local/`: managed files under `~/.local/`.
- `scripts/vendor-installers/`: idempotent installers for tools that manage
  their own binaries outside Homebrew.
- `scripts/`: helper scripts run manually or by chezmoi hooks.
- `run_*`: chezmoi scripts and hooks.

## Chezmoi Hooks

Chezmoi script prefixes control when setup scripts run:

- `run_once_before_*`: run once before applying files. This repo uses this to
  install Homebrew if it is missing.
- `run_onchange_*`: run when the rendered script changes. These hooks include
  checksums of their inputs so changes to files like `Brewfile`, mise config,
  macOS defaults, or Dock setup trigger the relevant command again.

Current hooks:

- `run_once_before_00_install-homebrew.sh.tmpl`: install Homebrew if needed.
- `run_onchange_10_brew-bundle.sh.tmpl`: run `brew bundle`.
- `run_onchange_15_mise-install.sh.tmpl`: run `mise install`.
- `run_onchange_20_macos-defaults.sh.tmpl`: apply selected macOS defaults.
- `run_onchange_30_dock.sh.tmpl`: add selected apps to the Dock.
- `run_onchange_35_vendor-installers.sh.tmpl`: run idempotent installers for
  vendor-managed tools.
- `run_onchange_40_yt-to-gobby.sh.tmpl`: prepare helper-script dependencies
  (only when `enableYtToGobby` is set; otherwise renders empty and is skipped).

## Installed Tools

Command-line tools:

- `chezmoi`: manages these dotfiles and applies them to `$HOME`.
- `git`: provides version control.
- `gh`: manages GitHub auth, repositories, pull requests, and SSH keys from the terminal.
- `curl`: fetches URLs and installer scripts.
- `wget`: downloads files from the web.
- `jq`: queries and transforms JSON.
- `rg`: searches text quickly.
- `fd`: finds files with a modern interface.
- `fzf`: provides fuzzy selection for files, history, and command output.
- `tree`: prints directory trees.
- `bat`: previews files with syntax highlighting.
- `eza`: lists files with modern formatting.
- `zoxide`: jumps to frequently used directories.
- `tmux`: runs persistent terminal sessions.
- `git-delta`: renders readable, syntax-highlighted Git diffs.
- `direnv`: loads reviewed per-project environment variables.
- `just`: runs project commands from `justfile` recipes.
- `hyperfine`: benchmarks shell commands.
- `btop`: monitors CPU, memory, disk, and processes.
- `dust`: summarizes disk usage by directory.
- `dua`: inspects disk usage interactively.
- `yazi`: browses files from the terminal.
- `starship`: renders the shell prompt.
- `antidote`: manages zsh plugins.
- `uv`: manages Python tools and project environments.
- `mise`: manages runtime versions such as Node.
- `pnpm`: manages JavaScript packages.
- `yt-dlp`: downloads video and metadata for personal workflows.
- `mas`: installs Mac App Store apps when authenticated.
- `dockutil`: updates the macOS Dock.

Vendor-managed command-line tools:

- Claude Code: installed with Anthropic's native installer instead of Homebrew
  because the native channel updates faster. The installer owns
  `~/.local/bin/claude` and `~/.local/share/claude/`; user settings and history
  live under `~/.claude/`.

To add another vendor-managed tool, create an idempotent installer under
`scripts/vendor-installers/`, then add a checksum line for it to
`run_onchange_35_vendor-installers.sh.tmpl` so chezmoi reruns the installer
group when that script changes. These scripts should install missing tools and
leave ongoing updates to the vendor tool itself when possible.

Applications:

- Google Chrome: primary Chromium browser.
- Arc: alternate browser.
- Helium: lightweight floating browser.
- Visual Studio Code: editor.
- Cursor: AI-assisted editor.
- Ghostty: terminal emulator.
- cmux: terminal workspace app.
- iTerm2: alternate terminal emulator.
- Raycast: launcher and automation tool.
- Notion: notes and workspace app.
- Obsidian: local Markdown knowledge base.
- Slack: team chat.
- Zoom: video calls.
- Figma: design tool.
- 1Password: password manager.
- 1Password CLI: command-line access to 1Password.
- AltTab: window switcher.
- Mos: mouse scrolling helper.
- OrbStack: local containers and Linux machines.

Fonts:

- Fira Code Nerd Font: coding font with icon glyphs.
- Geist Mono Nerd Font: coding font with icon glyphs.
- Mononoki Nerd Font: coding font with icon glyphs.

## Manual Setup

Some setup remains intentionally manual:

- Apple ID / App Store login
- iCloud
- Touch ID
- Privacy permissions such as Accessibility, Screen Recording, and Full Disk
  Access
- Browser login
- GitHub SSH key or `gh auth login`
- App-specific settings for editors, terminal apps, browsers, Raycast, and
  password manager

### GitHub SSH Key

This repo manages a reusable SSH client config, but it does not generate,
store, or upload private keys.

Create a per-machine key manually:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -b 4096 -C "$(git config --global user.email)" -f ~/.ssh/id_rsa
ssh-add --apple-use-keychain ~/.ssh/id_rsa
```

Add the public key to GitHub manually or with the GitHub CLI:

```sh
gh auth login
gh ssh-key add ~/.ssh/id_rsa.pub --title "$(hostname)-$(date +%Y-%m-%d)"
ssh -T git@github.com
```

Keep private host aliases, raw IPs, temporary keys, and machine-specific SSH
overrides in `~/.ssh/config.local`. The managed SSH config includes that file
when it exists. Move any existing private `Host` blocks there before applying
the managed SSH config.

## Health Check

After applying:

```sh
sh scripts/health-check.sh
```

The health check is read-only. Required setup failures return a non-zero exit
code; optional/manual items are warnings. When yt-to-gobby or Herdr config is
present on the machine, it also verifies `HERMES_YT_HOST` is set and that
Herdr's `new_cwd` directory exists.

## Secrets And Local Configuration

This repo intentionally does not store secrets.

Machine-specific credentials, tokens, remote hosts, and private environment
values should be configured outside the repo or in local-only files.

Git identity is templated during `chezmoi init` and stored in the local chezmoi
config, not hard-coded in the managed `.gitconfig`.

Chezmoi's `private_` path prefix sets restrictive file permissions on disk
(`600`); it does not hide those files from git. Keep machine-specific values in
`~/.config/chezmoi/chezmoi.toml` under `[data]`, for example:

```toml
[data]
    herdrDefaultCwd = "~/Projects/myorg"
```

## Included Utilities

Personal helper scripts live under `.local/bin/`, with supporting shell config
under `.config/zsh/custom/`.

The included `yt-to-gobby` helper expects user-provided environment values for
its upload target and is not meant to be a general-purpose public service.

It is **opt-in** and off by default. The `enableYtToGobby` flag defaults to
`false` in `.chezmoidata.toml`, so every machine skips it unless told
otherwise — including unattended bootstraps. When disabled, its files
(`.local/bin/yt-to-gobby`, `.local/share/yt-to-gobby`,
`.config/zsh/custom/yt-to-gobby.zsh`) are ignored and the dependency-install
hook renders empty.

To enable it on a personal machine, override the flag in that machine's local
`~/.config/chezmoi/chezmoi.toml` (which takes precedence over the repo
default):

```toml
[data]
    enableYtToGobby = true
    hermesYtHost = "root@your.vps.ip"
```
