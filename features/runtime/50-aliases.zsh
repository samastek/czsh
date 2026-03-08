alias myip="wget -qO- https://wtfismyip.com/text"
alias l="ls --hyperlink=auto -lAhrtF"
alias e="exit"
alias kp='ps -ef | fzf --multi | awk '\''{print $2}'\'' | xargs sudo kill -9'
alias g="gemini"
alias gai="gemini"
alias gcode="gemini"
alias gdebug="gemini"
alias gtest="gemini"
alias git-update-all='find . -type d -name .git -execdir git pull --rebase --autostash \;'

if command -v ip >/dev/null 2>&1; then
    alias ip="ip --color=auto"
fi