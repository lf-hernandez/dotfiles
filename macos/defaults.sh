#!/usr/bin/env bash
# macos/defaults.sh - Apply macOS system preferences via `defaults write`
# Run: bash ~/dotfiles/macos/defaults.sh
# Changes take effect after logout/reboot (or after killing affected apps below)
# NOTE: SIP must be disabled for some system-level preferences. Most user-level
#       preferences work without it.

set -euo pipefail

echo "Applying macOS preferences..."

# ── Close System Preferences to avoid conflicts ───────────────────────────────
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# ── Keyboard ──────────────────────────────────────────────────────────────────
# Fast key repeat (lower = faster; default is 6)
defaults write NSGlobalDomain KeyRepeat -int 2
# Short delay before key repeat starts (default is 68 = ~500ms; 15 = ~120ms)
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes (turns -- into —)
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable smart quotes (useful for coding)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ── Trackpad ──────────────────────────────────────────────────────────────────
# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Three-finger drag (accessibility setting)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# ── Finder ────────────────────────────────────────────────────────────────────
# Show hidden files (dotfiles) by default
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show status bar at the bottom of Finder windows
defaults write com.apple.finder ShowStatusBar -bool true
# Show path bar at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true
# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Search the current folder by default (instead of the whole Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Show ~/Library in Finder
chflags nohidden ~/Library 2>/dev/null || true
# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Disable .DS_Store on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Dock ──────────────────────────────────────────────────────────────────────
# Icon size (default is 64)
defaults write com.apple.dock tilesize -int 48
# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true
# Remove auto-hide delay (Dock appears instantly when mouse hits the edge)
defaults write com.apple.dock autohide-delay -float 0
# Speed up the hide/show animation
defaults write com.apple.dock autohide-time-modifier -float 0.3
# Don't show recently used apps in Dock
defaults write com.apple.dock show-recents -bool false
# Minimize windows using scale effect (faster than genie)
defaults write com.apple.dock mineffect -string "scale"
# Don't rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# ── Screenshots ───────────────────────────────────────────────────────────────
# Save screenshots to ~/Desktop/Screenshots
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location -string "~/Desktop/Screenshots"
# Save as PNG (options: png, jpg, pdf, gif, tiff, bmp)
defaults write com.apple.screencapture type -string "png"
# Disable screenshot shadows (cleaner screenshots of windows)
defaults write com.apple.screencapture disable-shadow -bool true

# ── Menu bar ──────────────────────────────────────────────────────────────────
# Show battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
# 24-hour clock
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true

# ── Activity Monitor ──────────────────────────────────────────────────────────
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0
# Update frequency: 2 = 2s (default is 5s)
defaults write com.apple.ActivityMonitor UpdatePeriod -int 2

# ── Safari (developer settings) ───────────────────────────────────────────────
# Enable Develop menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true
# Enable Web Inspector
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# ── TextEdit ──────────────────────────────────────────────────────────────────
# Open new documents in plain text mode (not rich text)
defaults write com.apple.TextEdit RichText -int 0
# Use UTF-8 encoding
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# ── Restart affected apps ─────────────────────────────────────────────────────
echo "Restarting affected apps..."
for app in Finder Dock SystemUIServer; do
    killall "$app" 2>/dev/null || true
done

echo "Done. Some changes may require a logout or reboot to take effect."
