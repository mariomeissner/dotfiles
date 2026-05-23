#!/bin/sh
set -eu

echo "Applying macOS defaults..."

###############################################################################
# Dock
###############################################################################

# Dock position: left, bottom, or right.
defaults write com.apple.dock orientation -string "left"

# Auto-hide Dock.
defaults write com.apple.dock autohide -bool true

# Use the system default Dock show/hide delay and animation time.
defaults delete com.apple.dock autohide-delay >/dev/null 2>&1 || true
defaults delete com.apple.dock autohide-time-modifier >/dev/null 2>&1 || true

# Dock icon size.
defaults write com.apple.dock tilesize -int 41

###############################################################################
# Keyboard / text
###############################################################################

# Disable press-and-hold accent popup so keys repeat normally.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Faster key repeat. Lower numbers are faster.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable smart text substitutions.
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Finder
###############################################################################

# Show hidden files.
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar.
defaults write com.apple.finder ShowPathbar -bool true

###############################################################################
# Screenshots
###############################################################################

mkdir -p "$HOME/Documents/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Documents/Screenshots"

###############################################################################
# Apply
###############################################################################

killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo
echo "macOS defaults summary:"
printf "  Dock orientation: "
defaults read com.apple.dock orientation 2>/dev/null || echo "unknown"
printf "  Dock autohide: "
defaults read com.apple.dock autohide 2>/dev/null || echo "unknown"
printf "  Dock tilesize: "
defaults read com.apple.dock tilesize 2>/dev/null || echo "unknown"
printf "  KeyRepeat: "
defaults read NSGlobalDomain KeyRepeat 2>/dev/null || echo "unknown"
printf "  InitialKeyRepeat: "
defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null || echo "unknown"
printf "  Finder path bar: "
defaults read com.apple.finder ShowPathbar 2>/dev/null || echo "unknown"
printf "  Screenshot location: "
defaults read com.apple.screencapture location 2>/dev/null || echo "unknown"

echo
echo "macOS defaults applied. Some settings may require logout or restart."
