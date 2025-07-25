export TERM="xterm-256color"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH_CUSTOM="$HOME/.config/czsh/oh-my-zsh/custom"
export ZSH="$HOME/.config/czsh/oh-my-zsh";


POWERLEVEL9K_MODE='nerdfont-complete'

ZSH_THEME="powerlevel10k/powerlevel10k"

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


# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)clear
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    zsh-completions
    zsh-autosuggestions # disable when using marker, otherwise enable
    zsh-syntax-highlighting
    history-substring-search
    screen
    systemd
    web-search
    extract
    z
    sudo
    docker
    fzf-tab
    forgit
)

if [[ -f $ZSH_CUSTOM/plugins/zsh_codex/zsh_codex.plugin.zsh ]]; then
    source $ZSH_CUSTOM/plugins/zsh_codex/zsh_codex.plugin.zsh
    bindkey '^X' create_completion
fi


export PATH=$PATH:~/.local/bin

export PATH=$PATH:~/.config/czsh/bin
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

NPM_PACKAGES="${HOME}/.npm"
PATH="$NPM_PACKAGES/bin:$PATH"

# Load nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ -s "$HOME/.config/czsh/marker/marker.sh" ]] && source "$HOME/.config/czsh/marker/marker.sh"




SAVEHIST=50000 #save upto 50,000 lines in history. oh-my-zsh default is 10,000
#setopt hist_ignore_all_dups     # dont record duplicated entries in history during a single session

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

# Load Gemini CLI configuration if available
[[ -f "$HOME/.config/czsh/gemini/config.sh" ]] && source "$HOME/.config/czsh/gemini/config.sh"

# GEMINI CLI FUNCTIONS AND ALIASES

# Quick start Gemini CLI
alias g="gemini"
alias gai="gemini"

# Gemini CLI with specific contexts
alias gcode="gemini"  # General code assistance
alias gdebug="gemini" # Debugging assistance 
alias gtest="gemini"  # Testing assistance

# Function to quickly start Gemini with a specific prompt
gask() {
    if [ "$1" ]; then
        echo "$*" | gemini
    else
        echo "Usage: gask <your question or prompt>"
        echo "Example: gask 'Explain this code and suggest improvements'"
    fi
}

# Function to use Gemini for code review on git changes
greview() {
    local target="${1:-HEAD~1}"
    git diff "$target" | gemini "Please review this git diff and provide feedback on code quality, potential issues, and suggestions for improvement:"
}

# Function to use Gemini for commit message generation
gcommit() {
    local staged_diff=$(git diff --staged)
    if [[ -z "$staged_diff" ]]; then
        echo "No staged changes found. Please stage your changes first with 'git add'."
        return 1
    fi
    
    echo "Staged changes:"
    git diff --staged --stat
    echo
    echo "Generating commit message with Gemini..."
    echo "$staged_diff" | gemini "Based on this git diff, generate a concise and descriptive commit message following conventional commit format. Only return the commit message, nothing else:"
}

# Function to explain error messages
gexplain() {
    if [ "$1" ]; then
        echo "Error: $*" | gemini "Please explain this error message and provide potential solutions:"
    else
        echo "Usage: gexplain <error message>"
        echo "Example: gexplain 'segmentation fault (core dumped)'"
    fi
}

# Function to use Gemini for documentation generation
gdoc() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file" | gemini "Please generate comprehensive documentation for this code file. Include function descriptions, usage examples, and any important notes:"
    else
        echo "Usage: gdoc <filename>"
        echo "Generate documentation for a code file using Gemini"
    fi
}

# Function to use Gemini for project analysis
ganalyze() {
    local path="${1:-.}"
    echo "Analyzing project structure in: $path"
    find "$path" -type f -name "*.md" -o -name "*.txt" -o -name "package.json" -o -name "requirements.txt" -o -name "Makefile" -o -name "*.yml" -o -name "*.yaml" | head -10 | xargs cat | gemini "Analyze this project structure and files. Provide insights about the project type, technologies used, and suggestions for improvement:"
}

alias git-update-all='find . -type d -name .git -execdir git pull --rebase --autostash \;'
