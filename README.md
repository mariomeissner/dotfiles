# Dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

These dotfiles are public for transparency and portability, but they are tuned
for my own machines. Review the source before applying it elsewhere.

The setup favors explicit, reviewable changes: inspect drift with `chezmoi diff`,
then apply intentionally.

## What This Manages

- Homebrew formulae and casks via `Brewfile`
- zsh login and interactive shell setup
- zsh plugins via Antidote
- Starship prompt configuration
- Node LTS via `mise`
- Python tooling via `uv`
- Ghostty and cmux terminal appearance
- Selected macOS defaults
- Dock setup
- A small set of personal helper scripts

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
- `dot_zprofile`: login-shell Homebrew and environment setup.
- `dot_zshrc`: interactive zsh setup.
- `dot_zsh_plugins.txt`: Antidote plugin list.
- `private_dot_config/`: managed files under `~/.config/`.
- `dot_local/`: managed files under `~/.local/`.
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
- `run_onchange_40_yt-to-gobby.sh.tmpl`: prepare helper-script dependencies
  (only when `enableYtToGobby` is set; otherwise renders empty and is skipped).

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

## Health Check

After applying:

```sh
sh scripts/health-check.sh
```

The health check is read-only. Required setup failures return a non-zero exit
code; optional/manual items are warnings.

## Secrets And Local Configuration

This repo intentionally does not store secrets.

Machine-specific credentials, tokens, remote hosts, and private environment
values should be configured outside the repo or in local-only files.

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
```
