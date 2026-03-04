# dotfiles

Personal dotfiles for Ubuntu 26.04 and macOS (Apple Silicon / Intel).

## Quick start

```bash
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` is **idempotent** — safe to re-run after pulling updates.

## What gets installed

### Packages

| Tool | Linux (apt) | macOS (brew) |
|------|-------------|--------------|
| git | ✓ | ✓ |
| vim | ✓ | ✓ |
| docker | docker.io | cask (manual) |
| htop | ✓ | ✓ |
| tmux | ✓ | ✓ |
| jq | ✓ | ✓ |
| ripgrep | ✓ | ✓ |
| fd | fd-find | fd |
| nvm | curl installer | brew |
| pyenv | — (install manually) | brew |
| build tools | build-essential | — |

### Symlinks created

```
~/.bashrc           → shell/.bashrc
~/.zshrc            → shell/.zshrc
~/.aliases          → shell/.aliases
~/.vimrc            → vim/.vimrc
~/.gitconfig        → git/.gitconfig
~/.gitignore_global → git/.gitignore_global
~/.ssh/config       → ssh/config
~/.docker/config.json → docker/config.json
```

## Repository structure

```
dotfiles/
├── install.sh          # Bootstrap script (run this first)
├── shell/
│   ├── .bashrc         # Bash config
│   ├── .zshrc          # Zsh config
│   └── .aliases        # Shared aliases (sourced by both shells)
├── vim/
│   └── .vimrc          # Vim config with vim-plug plugins
├── git/
│   ├── .gitconfig      # Global git config (no personal info)
│   └── .gitignore_global
├── ssh/
│   └── config          # SSH client config with example hosts
├── docker/
│   └── config.json     # Docker CLI defaults
├── macos/
│   └── defaults.sh     # macOS system preferences
└── README.md
```

## After install: required manual steps

### 1. Set git identity

Create `~/.gitconfig.local` (not tracked in git):

```ini
[user]
    name  = Your Name
    email = you@example.com
    # Optional: GPG signing
    # signingKey = YOUR_GPG_KEY_ID

# [commit]
#     gpgsign = true
```

### 2. Generate an SSH key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
# Then add the public key to GitHub/GitLab/servers:
cat ~/.ssh/id_ed25519.pub
```

Update `ssh/config` with your actual host IPs and usernames.

### 3. Install vim plugins

```bash
vim
:PlugInstall
```

vim-plug auto-installs on first launch, but `:PlugInstall` ensures everything is up to date.

### 4. Install a Python version (pyenv)

```bash
pyenv install 3.12          # or whichever version you need
pyenv global 3.12
```

### 5. Install a Node version (nvm)

```bash
nvm install --lts
nvm alias default lts/*
```

This is done automatically by `install.sh`, but you can upgrade later with the same commands.

## Machine-specific overrides

Add machine-specific settings to files that are **not** tracked in git:

| File | Purpose |
|------|---------|
| `~/.bashrc.local` | Extra bash config for this machine |
| `~/.zshrc.local` | Extra zsh config for this machine |
| `~/.gitconfig.local` | git identity, work email, signing key |

## Keeping dotfiles up to date

```bash
cd ~/dotfiles
git pull
bash install.sh   # re-run to apply any new symlinks or settings
```

## macOS preferences

```bash
bash ~/dotfiles/macos/defaults.sh
```

Highlights:
- Fast key repeat (delay: ~120ms, rate: ~30ms)
- Tap to click on trackpad
- Finder shows hidden files, path bar, status bar
- Dock auto-hides, 48px icons, no recent apps
- Screenshots saved to `~/Desktop/Screenshots` as PNG without shadows
- 24-hour clock
