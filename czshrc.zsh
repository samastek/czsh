export TERM="xterm-256color"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# CZSH Configuration (No Oh My Zsh dependency)
export CZSH_HOME="$HOME/.config/czsh"
export CZSH_PLUGINS_DIR="$CZSH_HOME/plugins"
export CZSH_THEMES_DIR="$CZSH_HOME/themes"

# Powerlevel10k configuration (standalone)
POWERLEVEL9K_MODE='nerdfont-complete'

# Theme path for standalone powerlevel10k
if [[ -d "$CZSH_THEMES_DIR/powerlevel10k" ]]; then
    source "$CZSH_THEMES_DIR/powerlevel10k/powerlevel10k.zsh-theme"
fi

POWERLEVEL9K_OS_ICON_BACKGROUND="white"
POWERLEVEL9K_OS_ICON_FOREGROUND="blue"
POWERLEVEL9K_DIR_HOME_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="white"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=( status command_execution_time background_jobs ram load)

# more prompt elements that are suggested
# (public_ip docker_machine pyenv nvm)          https://github.com/bhilburn/powerlevel9k#prompt-customization
# Note: using public_ip is cool but when connection is down prompt waits for 10-20 seconds

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)

POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# Plugin Management System (replacing Oh My Zsh)
declare -A CZSH_PLUGINS=(
    ["zsh-completions"]="$CZSH_PLUGINS_DIR/zsh-completions"
    ["zsh-autosuggestions"]="$CZSH_PLUGINS_DIR/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="$CZSH_PLUGINS_DIR/zsh-syntax-highlighting"
    ["history-substring-search"]="$CZSH_PLUGINS_DIR/history-substring-search"
    ["fzf-tab"]="$CZSH_PLUGINS_DIR/fzf-tab"
    ["forgit"]="$CZSH_PLUGINS_DIR/forgit"
)

# Load plugins function
load_plugin() {
    local plugin_name="$1"
    local plugin_path="${CZSH_PLUGINS[$plugin_name]}"
    
    if [[ -d "$plugin_path" ]]; then
        # Try different possible plugin file names
        if [[ -f "$plugin_path/$plugin_name.plugin.zsh" ]]; then
            source "$plugin_path/$plugin_name.plugin.zsh"
        elif [[ -f "$plugin_path/$plugin_name.zsh" ]]; then
            source "$plugin_path/$plugin_name.zsh"
        elif [[ -f "$plugin_path/${plugin_name#zsh-}.plugin.zsh" ]]; then
            source "$plugin_path/${plugin_name#zsh-}.plugin.zsh"
        elif [[ -f "$plugin_path/${plugin_name#zsh-}.zsh" ]]; then
            source "$plugin_path/${plugin_name#zsh-}.zsh"
        elif [[ -f "$plugin_path/init.zsh" ]]; then
            source "$plugin_path/init.zsh"
        else
            # Look for any .zsh file in the plugin directory
            local zsh_file=$(find "$plugin_path" -name "*.zsh" -type f | head -1)
            if [[ -n "$zsh_file" ]]; then
                source "$zsh_file"
            fi
        fi
    fi
}

# Load all plugins
for plugin in "${(@k)CZSH_PLUGINS}"; do
    load_plugin "$plugin"
done

# Load built-in zsh plugins (these come with zsh, no Oh My Zsh needed)
autoload -U compinit && compinit
autoload -U bashcompinit && bashcompinit

# Enable additional zsh features
setopt AUTO_CD              # Auto cd when typing just a path
setopt EXTENDED_GLOB        # Extended globbing patterns
setopt NOMATCH              # Print error when glob has no matches
setopt NOTIFY               # Report status of background jobs immediately
setopt CORRECT              # Command correction
setopt APPEND_HISTORY       # Append history instead of overwriting
setopt SHARE_HISTORY        # Share history between sessions
setopt HIST_IGNORE_DUPS     # Don't record duplicate entries
setopt HIST_IGNORE_SPACE    # Don't record entries starting with space
setopt HIST_REDUCE_BLANKS   # Remove extra blanks from history

# Built-in zsh functionality that replaces some Oh My Zsh plugins
# Web search function (replaces web-search plugin)
web_search() {
    local engine="$1"
    shift
    local query="$*"
    case "$engine" in
        google|g) open "https://www.google.com/search?q=${query// /+}" ;;
        duckduckgo|ddg) open "https://duckduckgo.com/?q=${query// /+}" ;;
        github|gh) open "https://github.com/search?q=${query// /+}" ;;
        stackoverflow|so) open "https://stackoverflow.com/search?q=${query// /+}" ;;
        *) echo "Usage: web_search <engine> <query>" ;;
    esac
}

# Extract function (replaces extract plugin)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Sudo functionality (replaces sudo plugin)
alias sudo='sudo '  # This allows aliases to work with sudo

# Docker aliases (replaces some docker plugin functionality)
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'

# Z functionality (can be replaced with built-in or standalone z.sh)
if [[ -f "$CZSH_PLUGINS_DIR/z/z.sh" ]]; then
    source "$CZSH_PLUGINS_DIR/z/z.sh"
fi

# zsh_codex plugin loading
if [[ -f "$CZSH_PLUGINS_DIR/zsh_codex/zsh_codex.plugin.zsh" ]]; then
    source "$CZSH_PLUGINS_DIR/zsh_codex/zsh_codex.plugin.zsh"
    bindkey '^X' create_completion
fi

export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/.config/czsh/bin
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

NPM_PACKAGES="${HOME}/.npm"
PATH="$NPM_PACKAGES/bin:$PATH"

[[ -s "$HOME/.config/czsh/marker/marker.sh" ]] && source "$HOME/.config/czsh/marker/marker.sh"

SAVEHIST=50000 #save upto 50,000 lines in history
HISTSIZE=50000

# Custom aliases
alias myip="wget -qO- https://wtfismyip.com/text" # quickly show external ip address
alias l="ls --hyperlink=auto -lAhrtF"             # show all except . .. , sort by recent, / at the end of folders, clickable
alias e="exit"
alias ip="ip --color=auto"

# CUSTOM FUNCTIONS

# cheat sheets (github.com/chubin/cheat.sh), find out how to use commands
# example 'cheat tar'
# for language specific question supply 2 args first for language, second as the question
# eample: cheat python3 execute external program
cheat() {
    if [ "$2" ]; then
        curl "https://cheat.sh/$1/$2+$3+$4+$5+$6+$7+$8+$9+$10"
        else
        curl "https://cheat.sh/$1"
    fi
}

# Matrix screen saver! will run if you have installed "cmatrix"
# TMOUT=900
# TRAPALRM() { if command -v cmatrix &> /dev/null; then cmatrix -sb; fi }

speedtest() {
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
}

s() {
    local query="${1}"
    
    # Check if the query is empty and exit with an error message
    if [[ -z "$query" ]]; then
        echo "⚠️  No search term provided! Please provide a valid search term. 🔍"
        return 1
    fi
    
    rg --line-number "$query" | \
        fzf --preview "batcat --style=numbers --color=always --highlight-line {2} {1}" \
            --delimiter : --preview-window=up:wrap
}

f() { find . -type f -print0 | fzf --read0 --preview 'batcat --color=always {}' | xargs -0 file -b; }

git config --global alias.amend '!git add -u && git commit --amend --no-edit && git push -f'

alias kp='ps -ef | fzf --multi | awk '\''{print $2}'\'' | xargs sudo kill -9'
alias git-update-all='find . -type d -name .git -execdir git pull --rebase --autostash \;'
