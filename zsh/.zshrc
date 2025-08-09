# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""
export PATH="${PATH}:/Users/liebl/Library/Python/3.12/lib/python/site-packages"
export PATH="/Applications/PyCharm.app/Contents/MacOS:$PATH"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=("$(brew --prefix)/share/zsh/site-functions")
autoload -U promptinit; promptinit
prompt pure

export CONFIG=$HOME/.config/
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1


# general aliases
alias cl='clear'
alias v='nvim'

# git aliases
alias gbi='git branch | fzf | xargs git checkout'
alias gbd='git branch | fzf | xargs git branch -D'
alias gsidx='git ls-files -v | grep "^S" | cut -c 3-'  # List files with the skip-worktree flag
alias gnidx='git ls-files -v | grep "^S" | cut -c 3- | xargs git update-index --no-skip-worktree'  # Remove skip-worktree flag
alias gidx='git update-index --skip-worktree'  # Add skip-worktree flag
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
alias gdiff='git diff --no-index'
alias gdc='git diff --cached'
alias gstf='git status --porcelain | grep -v "^??" | cut -c 4-'


alias python='python3'
#alias pip='pip3'

alias ds='find . -name ".DS_Store" -depth -exec rm {} \;'
alias l='eza -1 --icons --color=always'
alias la='eza --long --color=always --icons=always --no-user'
alias icat='wezterm imgcat'
alias dro='docker compose down -v --remove-orphans'
alias czc='cz check -m "$(git log -1 --pretty=%B)"'
alias s='source ~/.zshrc'
alias e='nvim ~/.zshrc'
alias a='nvim ~/.config/aerospace/aerospace.toml'
alias al='aerospace list-apps'
alias w='nvim ~/.wezterm.lua'
alias c='z ~/.config/'
alias t='tree -a -I ".git|__pycache__|.pytest_cache|.mypy_cache|.ruff_cache|helm|\..*|static|.idea"'
alias typora='open -a Typora'
alias openbb="/Users/liebl/Documents/tools/openbb-terminal/openbb.sh"
alias ups="uv pip sync requirements.txt"
alias uv311="uv venv --python /opt/homebrew/opt/python@3.11/bin/python3.11"
alias pfloki='kubectl port-forward svc/loki-gateway 3100:80 -n loki'
#alias logcli='logcli --timezone=Local'
alias skopy='echo "AWS Profile: $(aws configure get sso_account_id --profile artifacts 2>/dev/null || echo "Not authenticated")" && aws sts get-caller-identity --profile artifacts >/dev/null 2>&1 && echo "AWS authenticated" || (echo "AWS not authenticated - run: aws sso login --profile artifacts" && exit 1) && uv run /Users/liebl/Documents/tools/skopy/skopy'

zipnoh() {
  zip -r "$1" "$2" -x '*/.*' '*/.*/*' '*/__pycache__/*' '*/tests/*' -i '*.py'
}

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

obsidian() {
  vault_name="default"  # Your Obsidian vault name
  vault_path=~/Documents/default/Misc/quickedits  # Correct target folder

  if [ -z "$1" ]; then
    echo "Usage: obsidian <file-path>"
    return 1
  fi

  fullpath=$(realpath "$1")  # Get absolute path
  filename=$(basename "$fullpath")  # Extract filename
  relative_path="Misc/quickedits/$filename"  # Correct relative path inside the vault

  # Ensure the quickedits folder exists
  mkdir -p "$vault_path"

  # Copy the file if it's missing or outdated
  if [ ! -e "$vault_path/$filename" ] || [ "$fullpath" -nt "$vault_path/$filename" ]; then
    cp "$fullpath" "$vault_path/$filename"
    echo "Copied: $fullpath → $vault_path/$filename"
  fi

  # Encode the file path for Obsidian's URI
  encoded_path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$relative_path'))")

  # Open in Obsidian using the correct vault name
  open "obsidian://open?vault=$vault_name&file=$encoded_path"
}


# Open the latest markdown file in Typora
cht() {
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)  # Get the repo root
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

# Open the latest markdown file in Obsidian
cho() {
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)  # Get the repo root
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

llm_cmd_from_buffer() {
  local input="$BUFFER"
  BUFFER="llm cmd \"$input\""
  zle accept-line
}
zle -N llm_cmd_from_buffer
bindkey "^[[13;2u" llm_cmd_from_buffer

#bindkey '^ ' autosuggest-accept
#source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/Users/liebl/.cache/lm-studio/bin"

eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
export FZF_TMUX_OPTS=" -p90%,70% "
alias fman="compgen -c | fzf | xargs man"

# add CloudyPad CLI PATH
export PATH=$PATH:/Users/liebl/.cloudypad/bin

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# Added by Windsurf
export PATH="/Users/liebl/.codeium/windsurf/bin:$PATH"

eval "$(zoxide init zsh)"

#neofetch

# Created by `pipx` on 2025-04-05 22:24:05
export PATH="$PATH:/Users/liebl/.local/bin"

# espanso
# launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/dev.espanso.custom.plist
# launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.espanso.custom.plist
# espanso stop

# Added by Windsurf - Next
export PATH="/Users/liebl/.codeium/windsurf/bin:$PATH"
alias claude="/Users/liebl/.claude/local/claude"
export EDITOR=nvim

# bun completions
[ -s "/Users/liebl/.bun/_bun" ] && source "/Users/liebl/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export CARGO_REGISTRIES_UNI_CREDENTIAL_PROVIDER=cargo:token
