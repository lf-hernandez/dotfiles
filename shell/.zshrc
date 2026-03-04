# ~/.zshrc - interactive zsh configuration
# Sourced for every interactive zsh session

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=100000
setopt APPEND_HISTORY           # append rather than overwrite history file
setopt SHARE_HISTORY            # share history across all zsh sessions
setopt HIST_IGNORE_DUPS         # don't record duplicate consecutive entries
setopt HIST_IGNORE_ALL_DUPS     # remove older duplicates when new one is added
setopt HIST_IGNORE_SPACE        # don't record lines starting with a space
setopt HIST_REDUCE_BLANKS       # remove superfluous blanks before recording
setopt HIST_VERIFY              # don't execute history expansion immediately

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit
compinit -C                     # -C: skip security check for speed (safe on single-user)
zstyle ':completion:*' menu select          # interactive completion menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Options ───────────────────────────────────────────────────────────────────
setopt AUTO_CD                  # type directory name to cd into it
setopt CORRECT                  # auto-correct minor typos in commands
setopt NO_BEEP                  # silence audible bell
setopt EXTENDED_GLOB            # extended globbing patterns
setopt GLOB_DOTS                # include dotfiles in glob results (without explicit .)
setopt INTERACTIVE_COMMENTS     # allow # comments in interactive shell

# ── Key bindings ──────────────────────────────────────────────────────────────
bindkey -e                      # emacs key bindings (Ctrl+A, Ctrl+E, etc.)
bindkey '^[[A' history-search-backward   # up arrow: search history with prefix
bindkey '^[[B' history-search-forward    # down arrow: search history with prefix
bindkey '^[[H' beginning-of-line         # Home key
bindkey '^[[F' end-of-line               # End key

# ── Prompt ────────────────────────────────────────────────────────────────────
autoload -Uz vcs_info           # built-in VCS information
precmd() { vcs_info }           # update VCS info before each prompt

zstyle ':vcs_info:git:*' formats ' (%b)'           # show branch name
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'  # show branch + action (rebase, merge...)

setopt PROMPT_SUBST             # allow command substitution in PS1

# user@host:~/path (branch) %
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '

# ── Path ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Homebrew (macOS - Apple Silicon)
if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# Homebrew (macOS - Intel)
if [[ -d "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ── pyenv ─────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ── nvm ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
elif [[ -s "$(brew --prefix 2>/dev/null)/opt/nvm/nvm.sh" ]]; then
    source "$(brew --prefix)/opt/nvm/nvm.sh"
fi
# nvm completion for zsh
if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
fi

# ── Shared aliases ────────────────────────────────────────────────────────────
DOTFILES_DIR="${0:A:h:h}"  # parent of the shell/ directory (zsh parameter expansion)
[[ -f "$DOTFILES_DIR/shell/.aliases" ]] && source "$DOTFILES_DIR/shell/.aliases"
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ── Editor / Pager ───────────────────────────────────────────────────────────
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export LESS='-R --quit-if-one-screen --no-init'

# ── Local overrides ───────────────────────────────────────────────────────────
# Machine-specific settings (not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
