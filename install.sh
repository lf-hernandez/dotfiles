#!/usr/bin/env bash
# install.sh - Bootstrap dotfiles on a fresh machine
# Safe to run multiple times (idempotent).
# Usage: bash ~/dotfiles/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { printf '\e[34m[info]\e[0m  %s\n' "$*"; }
success() { printf '\e[32m[ok]\e[0m    %s\n' "$*"; }
warn()    { printf '\e[33m[warn]\e[0m  %s\n' "$*"; }
error()   { printf '\e[31m[error]\e[0m %s\n' "$*" >&2; }

# Create a symlink, backing up any existing file/dir/link first.
# Usage: link <source> <dest>
link() {
    local src="$1" dst="$2"

    # Expand ~ in destination
    dst="${dst/#\~/$HOME}"

    # If destination already points to the right place, skip
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        success "Already linked: $dst"
        return
    fi

    # Back up existing file (not a symlink)
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up $dst → $backup"
        mv "$dst" "$backup"
    fi

    # Remove stale symlink
    [[ -L "$dst" ]] && rm "$dst"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    ln -sf "$src" "$dst"
    success "Linked: $dst → $src"
}

# Run a command only if it's not already installed / done.
# Usage: installed <command>
installed() { command -v "$1" &>/dev/null; }

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Linux)   PLATFORM="linux" ;;
    Darwin)  PLATFORM="macos" ;;
    *)       error "Unsupported OS: $OS"; exit 1 ;;
esac

info "Detected platform: $PLATFORM"

# ── Package installation ──────────────────────────────────────────────────────

install_linux_packages() {
    info "Updating apt and installing packages..."

    sudo apt-get update -qq

    local packages=(
        build-essential   # gcc, make, etc. — needed to compile many tools
        curl              # HTTP client
        git               # version control
        vim               # text editor
        docker.io         # container runtime
        htop              # interactive process viewer
        tmux              # terminal multiplexer
        jq                # JSON processor
        ripgrep           # fast grep (command: rg)
        fd-find           # modern find replacement (command: fdfind, aliased to fd)
        unzip             # needed by some installers
        wget              # alternative HTTP client
        gnupg             # GPG for signing commits / verifying packages
        ca-certificates   # updated TLS certificates
    )

    sudo apt-get install -y --no-install-recommends "${packages[@]}"
    success "apt packages installed."

    # Add current user to the docker group so docker works without sudo
    if ! groups "$USER" | grep -q '\bdocker\b'; then
        sudo usermod -aG docker "$USER"
        warn "Added $USER to the docker group. Log out and back in for this to take effect."
    fi
}

install_macos_packages() {
    # Install Homebrew if missing
    if ! installed brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for the rest of this script
        if [[ -d "/opt/homebrew/bin" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        info "Homebrew already installed, running brew update..."
        brew update --quiet
    fi

    info "Installing brew packages..."

    local formulae=(
        git           # version control
        vim           # text editor
        htop          # interactive process viewer
        tmux          # terminal multiplexer
        jq            # JSON processor
        ripgrep       # fast grep
        fd            # modern find replacement
        nvm           # Node version manager
        pyenv         # Python version manager
        curl          # HTTP client (macOS system curl is old)
        wget          # alternative HTTP client
        gnupg         # GPG
    )

    for pkg in "${formulae[@]}"; do
        if brew list --formula "$pkg" &>/dev/null; then
            success "Already installed: $pkg"
        else
            info "Installing $pkg..."
            brew install "$pkg"
        fi
    done

    # Docker Desktop is distributed as a cask (GUI app), not a formula.
    # Install via: brew install --cask docker
    # Or download from https://www.docker.com/products/docker-desktop/
    if ! installed docker; then
        warn "Docker not found. Install Docker Desktop: brew install --cask docker"
    fi

    success "brew packages installed."
}

case "$PLATFORM" in
    linux) install_linux_packages ;;
    macos) install_macos_packages ;;
esac

# ── Symlinks ──────────────────────────────────────────────────────────────────
info "Creating symlinks..."

# Shell
link "$DOTFILES_DIR/shell/.bashrc"   ~/.bashrc
link "$DOTFILES_DIR/shell/.zshrc"    ~/.zshrc
link "$DOTFILES_DIR/shell/.aliases"  ~/.aliases

# Vim
link "$DOTFILES_DIR/vim/.vimrc"      ~/.vimrc

# Git
link "$DOTFILES_DIR/git/.gitconfig"         ~/.gitconfig
link "$DOTFILES_DIR/git/.gitignore_global"  ~/.gitignore_global

# SSH config (the directory must exist with correct permissions)
mkdir -p ~/.ssh
chmod 700 ~/.ssh
link "$DOTFILES_DIR/ssh/config"      ~/.ssh/config
chmod 600 ~/.ssh/config 2>/dev/null || true

# Docker config
mkdir -p ~/.docker
link "$DOTFILES_DIR/docker/config.json"  ~/.docker/config.json

# Claude Code config
link "$DOTFILES_DIR/claude/CLAUDE.md"                              ~/.claude/CLAUDE.md
link "$DOTFILES_DIR/claude/settings.json"                          ~/.claude/settings.json
link "$DOTFILES_DIR/claude/statusline-command.sh"                  ~/.claude/statusline-command.sh
link "$DOTFILES_DIR/claude/agents/code-improvement-advisor.md"     ~/.claude/agents/code-improvement-advisor.md
link "$DOTFILES_DIR/claude/skills/review/SKILL.md"                 ~/.claude/skills/review/SKILL.md
link "$DOTFILES_DIR/claude/skills/verify/SKILL.md"                 ~/.claude/skills/verify/SKILL.md
link "$DOTFILES_DIR/claude/hooks/validate-destructive.sh"          ~/.claude/hooks/validate-destructive.sh
chmod +x "$DOTFILES_DIR/claude/statusline-command.sh" "$DOTFILES_DIR/claude/hooks/validate-destructive.sh"

# ── SSH socket directory ───────────────────────────────────────────────────────
# ControlPath in ssh/config uses ~/.ssh/sockets/; it must exist
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# ── One-time setup ────────────────────────────────────────────────────────────

# vim-plug will auto-install the first time vim is opened (see .vimrc).
# Pre-create the undo directory so vim doesn't complain.
mkdir -p ~/.vim/undo

# ── nvm: install latest LTS Node (Linux, or macOS without nvm yet) ─────────────
if [[ -z "${NVM_DIR:-}" ]]; then
    export NVM_DIR="$HOME/.nvm"
fi
# Load nvm if available
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
elif [[ -s "$(brew --prefix 2>/dev/null)/opt/nvm/nvm.sh" ]]; then
    source "$(brew --prefix)/opt/nvm/nvm.sh"
fi

if installed nvm; then
    if ! nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        info "Installing latest LTS Node via nvm..."
        nvm install --lts
        nvm alias default 'lts/*'
    else
        success "Node LTS already installed via nvm."
    fi
elif [[ "$PLATFORM" == "linux" ]]; then
    # Install nvm itself on Linux (brew does it on macOS)
    if [[ ! -d "$NVM_DIR" ]]; then
        info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        source "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm alias default 'lts/*'
    fi
fi

# ── macOS defaults ────────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "macos" ]]; then
    read -rp "Apply macOS system preferences? [y/N] " apply_macos
    if [[ "$apply_macos" =~ ^[Yy]$ ]]; then
        bash "$DOTFILES_DIR/macos/defaults.sh"
    fi
fi

# ── Shell detection / reminder ────────────────────────────────────────────────
CURRENT_SHELL="$(basename "$SHELL")"
info "Current shell: $CURRENT_SHELL"
if [[ "$CURRENT_SHELL" == "bash" ]]; then
    info "Run: source ~/.bashrc"
elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
    info "Run: source ~/.zshrc"
fi

echo ""
success "Dotfiles installed! Open a new terminal (or source your rc file) to load the new config."
echo ""
echo "  Next steps:"
echo "  1. Set your git identity: edit ~/.gitconfig.local"
echo "     [user]"
echo "         name  = Your Name"
echo "         email = you@example.com"
echo "  2. Generate an SSH key if you don't have one:"
echo "     ssh-keygen -t ed25519 -C 'you@example.com'"
echo "  3. Open vim and run :PlugInstall to install vim plugins."
echo ""
