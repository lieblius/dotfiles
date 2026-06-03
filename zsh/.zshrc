# =============================================================================
# ZSH & Oh-My-Zsh Configuration
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Environment Variables
# =============================================================================

export CONFIG=$HOME/.config/
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
export EDITOR=nvim
export BROWSER=open
export BUN_INSTALL="$HOME/.bun"
export LINEAR_ISSUE_SORT=priority
export TELEPORT_TOOLS_VERSION=off

# Privacy & telemetry
export DISABLE_ERROR_REPORTING=1

# Source secrets
[ -f ~/.zshsecrets ] && source ~/.zshsecrets

# Expose API keys to macOS GUI apps (Electron, etc.)
launchctl setenv ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY" 2>/dev/null

# CodeArtifact environment variables
[ -f ~/.config/codeartifact-auth-manager/env.sh ] && source ~/.config/codeartifact-auth-manager/env.sh

# =============================================================================
# PATH Configuration
# =============================================================================

export PATH="$HOME/.local/bin:$PATH"
export PATH="${PATH}:/Users/liebl/Library/Python/3.12/lib/python/site-packages"
export PATH="/Applications/PyCharm.app/Contents/MacOS:$PATH"
export PATH="$PATH:/Users/liebl/.cache/lm-studio/bin"
export PATH="$PATH:/Users/liebl/.cloudypad/bin"
export PATH="/Users/liebl/.codeium/windsurf/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# =============================================================================
# Prompt Setup
# =============================================================================

fpath+=("$(brew --prefix)/share/zsh/site-functions")
autoload -U promptinit; promptinit
prompt pure

# =============================================================================
# Aliases
# =============================================================================

# General
alias cl='clear'
alias v='nvim'
alias ds='find . -name ".DS_Store" -depth -exec rm {} \;'
alias python='python3'
alias s='source ~/.zshrc'
alias e='nvim ~/.zshrc'

# File & Directory
alias l='eza -1 --icons --color=always'
alias la='eza --long --color=always --icons=always --no-user'
alias icat='wezterm imgcat'
alias c='z ~/.config/'
alias t='tree -a -I ".git|__pycache__|.pytest_cache|.mypy_cache|.ruff_cache|helm|\..*|static|.idea"'

# Config Files
alias a='nvim ~/.config/aerospace/aerospace.toml'
alias w='nvim ~/.wezterm.lua'

# Git
alias gprw='gh pr view --web'
alias ghb='gh browse'
alias gbi='git branch | fzf | xargs git checkout'
alias gbd='git branch | fzf | xargs git branch -D'
alias gdiff='git diff --no-index'
alias gdc='git diff --cached'
alias gstf='git status --porcelain | grep -v "^??" | cut -c 4-'
alias gstfpy='git status --porcelain | grep "\.py$" | grep -v "^D " | grep -v "^ D" | cut -c 4-'
alias gfmt='uvx ruff format $(gstfpy) && uvx ruff check --fix --unsafe-fixes $(gstfpy)'
alias gcamai='gcai -a'

# Git skip-worktree
alias gsidx='git ls-files -v | grep "^S" | cut -c 3-'
alias gnidx='git ls-files -v | grep "^S" | cut -c 3- | xargs git update-index --no-skip-worktree'
alias gidx='git update-index --skip-worktree'

# Docker
alias dro='docker compose down -v --remove-orphans'

# Development Tools
alias czc='cz check -m "$(git log -1 --pretty=%B)"'
alias al='aerospace list-apps'
alias typora='open -a Typora'
alias openbb="/Users/liebl/Documents/tools/openbb-terminal/openbb.sh"
alias ups="uv pip sync requirements.txt"
alias uv311="uv venv --python /opt/homebrew/opt/python@3.11/bin/python3.11"
alias pfloki='kubectl port-forward svc/loki-gateway 3100:80 -n loki'
alias mcp='npx mcpick'
alias skopy='echo "AWS Profile: $(aws configure get sso_account_id --profile artifacts 2>/dev/null || echo "Not authenticated")" && aws sts get-caller-identity --profile artifacts >/dev/null 2>&1 && echo "AWS authenticated" || (echo "AWS not authenticated - run: aws sso login --profile artifacts" && exit 1) && uv run /Users/liebl/Documents/tools/skopy/skopy'
#alias slurp="$HOME/Documents/docs/slurp.sh"
alias ca-auth="$HOME/.config/codeartifact-auth-manager/manager.py refresh && source $HOME/.config/codeartifact-auth-manager/env.sh"
alias ca-status="$HOME/.config/codeartifact-auth-manager/manager.py status"

# =============================================================================
# Functions
# =============================================================================

# Git Functions
gwr() {
  git worktree list | tail -n +2 | fzf --height=10 | while read -r line; do
    local wt_path=$(echo $line | awk '{print $1}')
    local branch=$(echo $line | awk '{print $3}' | tr -d '[]')
    git worktree remove "$wt_path" --force && git branch -D "$branch"
  done
}

glidx() {
    SKIPPED_FILES=$(git ls-files -v | grep "^S" | cut -c 3-)
    if [ -z "$SKIPPED_FILES" ]; then
        echo "No skip-worktree files found."
        return
    fi
    echo "$SKIPPED_FILES" | xargs git update-index --no-skip-worktree
    git stash push -m "Stashing skip-worktree files" -- $(echo "$SKIPPED_FILES")
    git pull
    git stash pop
    echo "$SKIPPED_FILES" | xargs git update-index --skip-worktree
    git ls-files -v | grep "^S" | cut -c 3-
}

gidxt() {
  tracked_files=$(git diff --name-only)
  if [ -z "$tracked_files" ]; then
    echo "No tracked files with changes found."
  else
    echo "Applying skip-worktree to tracked files:"
    echo "$tracked_files" | while read file; do
    echo "  $file"
    gidx "$file"
  done
    echo "Done. Use 'gsidx' to see skipped files."
  fi
}

# Docker Functions
ilogs() {
  docker logs --follow $(docker ps --format '{{.ID}} {{.Names}}' | \
    fzf --prompt="Select a container: " \
        --preview="docker logs {1} --follow" \
        --preview-window=right:70% | awk '{print $1}')
}

ibash() {
  docker exec -it $(docker ps --format '{{.ID}} {{.Names}}' | \
    fzf --prompt="Select a container: " \
        --preview="docker logs {1} --follow" \
        --preview-window=right:70% | awk '{print $1}') bash
}

ish() {
  docker exec -it $(docker ps --format '{{.ID}} {{.Names}}' | \
    fzf --prompt="Select a container: " \
        --preview="docker logs {1} --follow" \
        --preview-window=right:70% | awk '{print $1}') sh
}

# Utility Functions
zipnoh() {
  zip -r "$1" "$2" -x '*/.*' '*/.*/*' '*/__pycache__/*' '*/tests/*' -i '*.py'
}

# File Management Functions
obsidian() {
  vault_name="default"
  vault_path=~/Documents/default/Misc/quickedits

  if [ -z "$1" ]; then
    echo "Usage: obsidian <file-path>"
    return 1
  fi

  fullpath=$(realpath "$1")
  filename=$(basename "$fullpath")
  relative_path="Misc/quickedits/$filename"

  mkdir -p "$vault_path"

  if [ ! -e "$vault_path/$filename" ] || [ "$fullpath" -nt "$vault_path/$filename" ]; then
    cp "$fullpath" "$vault_path/$filename"
    echo "Copied: $fullpath → $vault_path/$filename"
  fi

  encoded_path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$relative_path'))")
  open "obsidian://open?vault=$vault_name&file=$encoded_path"
}

cht() {
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$repo_root" ]; then
    echo "Not inside a Git repository."
    return 1
  fi

  latest_file=$(ls -t "$repo_root/.specstory/history/"*.md 2>/dev/null | head -n 1)

  if [ -z "$latest_file" ]; then
    echo "No markdown files found in $repo_root/.specstory/history/"
    return 1
  fi

  echo "Opening latest file in Typora: $latest_file"
  typora "$latest_file"
}

cho() {
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$repo_root" ]; then
    echo "Not inside a Git repository."
    return 1
  fi

  latest_file=$(ls -t "$repo_root/.specstory/history/"*.md 2>/dev/null | head -n 1)

  if [ -z "$latest_file" ]; then
    echo "No markdown files found in $repo_root/.specstory/history/"
    return 1
  fi

  echo "Opening latest file in Obsidian: $latest_file"
  obsidian "$latest_file"
}

catdelim() {
  local dir="$1"
  local outfile="$2"

  if [[ -z "$dir" ]]; then
    echo "Usage: catdelim <directory> [outfile]"
    return 1
  fi

  if [[ -n "$outfile" ]]; then
    exec > "$outfile"
  fi

  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    echo "---- ${f##*/} ----"
    cat "$f"
    echo
  done
}

# =============================================================================
# FZF Configuration
# =============================================================================

eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_F_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_CTRL_F_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# Bind Ctrl+F to FZF directory search (instead of default Alt+C)
bindkey '^F' fzf-cd-widget
export FZF_TMUX_OPTS=" -p90%,70% "
alias fman="compgen -c | fzf | xargs man"

# =============================================================================
# Tool Initialization
# =============================================================================

# Cargo environment
. "$HOME/.cargo/env"


# Zoxide (better cd)
eval "$(zoxide init zsh)"

# mise (runtime & env management)
eval "$(mise activate zsh)"

# Bun completions
[ -s "/Users/liebl/.bun/_bun" ] && source "/Users/liebl/.bun/_bun"

# opencode
export PATH=/Users/liebl/.opencode/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity
export PATH="/Users/liebl/.antigravity/antigravity/bin:$PATH"

# OpenCode: patched build -- disable auto-update and raise tool output limits
export OPENCODE_DISABLE_AUTOUPDATE=true
export OPENCODE_MAX_TOOL_OUTPUT_BYTES=3145728
export OPENCODE_MAX_TOOL_OUTPUT_LINES=100000

# pnpm
export PNPM_HOME="/Users/liebl/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
