# Fix: drain stale ANSI cursor position report (CPR) responses from the
# terminal input buffer.  When a program that queried cursor position
# (\e[6n) is killed (e.g. Ctrl-C), the terminal's reply (\e[row;colR)
# may still be in the input buffer and zsh would interpret it as commands
# like ";1R", ";117R" etc.

# Flush any pending CPR responses before each prompt.
function _drain_cpr_responses() {
    local char
    # Read any pending input with a tiny timeout
    while read -t 0.01 -sk 1 char 2>/dev/null; do
        :  # discard
    done
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _drain_cpr_responses
