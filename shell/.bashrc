# ~/.bashrc - interactive bash shell configuration
# Sourced for interactive non-login shells; login shells source ~/.bash_profile

# Skip if not running interactively
[[ $- != *i* ]] && return

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups    # no duplicate entries, ignore lines starting with space
HISTTIMEFORMAT="%F %T "             # timestamp history entries
shopt -s histappend                 # append to history file, don't overwrite
# Write to history after every command (multi-terminal friendly)
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# ── Shell options ─────────────────────────────────────────────────────────────
shopt -s cdspell                    # auto-correct minor typos in cd
shopt -s checkwinsize               # update LINES/COLUMNS after each command
shopt -s globstar                   # ** glob matches recursively
shopt -s nocaseglob                 # case-insensitive globbing

# ── Prompt ────────────────────────────────────────────────────────────────────
# Colors
_RESET='\[\e[0m\]'
_BOLD='\[\e[1m\]'
_RED='\[\e[31m\]'
_GREEN='\[\e[32m\]'
_YELLOW='\[\e[33m\]'
_BLUE='\[\e[34m\]'
_CYAN='\[\e[36m\]'

# Show git branch in prompt if in a git repo
_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && echo " (${branch})"
}

# user@host:~/path (branch) $
PS1="${_GREEN}\u@\h${_RESET}:${_BLUE}\w${_YELLOW}\$(_git_branch)${_RESET} \$ "

# ── Path ──────────────────────────────────────────────────────────────────────
# Local binaries take precedence
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ── pyenv ─────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ── nvm ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
# Load nvm (installed via install.sh or brew)
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    source "$NVM_DIR/bash_completion"   # tab completion for nvm commands
elif [[ -s "$(brew --prefix 2>/dev/null)/opt/nvm/nvm.sh" ]]; then
    source "$(brew --prefix)/opt/nvm/nvm.sh"
fi

# ── Shared aliases ────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$DOTFILES_DIR/shell/.aliases" ]] && source "$DOTFILES_DIR/shell/.aliases"
# Also support direct symlink at ~/.aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR='vim'
export VISUAL='vim'

# ── Pager ─────────────────────────────────────────────────────────────────────
export PAGER='less'
export LESS='-R --quit-if-one-screen --no-init'  # -R: colors, quit if fits one screen

# ── ripgrep ───────────────────────────────────────────────────────────────────
# Use a config file if it exists
[[ -f "$HOME/.config/ripgrep/ripgreprc" ]] && export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"

# ── Local overrides ───────────────────────────────────────────────────────────
# Machine-specific settings (not tracked in git)
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
