# Omarchy-compatible zsh configuration
# Source omarchy bash setup for compatibility
source ~/.local/share/omarchy/default/bash/bashrc 2>/dev/null || true

# Basic zsh setup
export PS1='[%n@%m %c]$ '
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Personal zsh configuration migrated from .zshrc.local

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias c="ccr code"

# Environment variables
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH=/home/kyle/.opencode/bin:$PATH
export PATH=/home/kyle/.claude/local:$PATH
export PATH="$PATH:$HOME/.local/share/omarchy/bin"
export GTK_THEME=Tokyonight-Dark

# zoxide for smart cd
eval "$(zoxide init zsh)"

# Adaptive fastfetch function
ff() {
    local reported_width=$(tput cols)
    local logo_content_width=$(fastfetch 2>/dev/null | wc -L)
    local small_logo_width=$(fastfetch --logo-width 8 2>/dev/null | wc -L)
    local no_logo_width=$(fastfetch --logo none 2>/dev/null | wc -L)
    
    local logo_threshold=$((logo_content_width + 5))
    local small_threshold=$((small_logo_width + 5))
    local no_logo_threshold=$((no_logo_width + 5))
    
    if [ "$reported_width" -lt 20 ]; then
        return
    elif [ "$reported_width" -lt 40 ]; then
        fastfetch --logo none
    elif [ "$reported_width" -lt "$small_threshold" ]; then
        fastfetch --logo none
    elif [ "$reported_width" -lt "$logo_threshold" ]; then
        fastfetch --logo-width 8
    else
        fastfetch
    fi
}

if [ -z "$WEZTERM_PANE" ] || [ "$WEZTERM_PANE" = "0" ]; then
    ff
fi