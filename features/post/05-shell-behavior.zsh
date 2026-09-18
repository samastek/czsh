# Make interactive parsing less surprising for commands written with Bash in
# mind. These run after Oh My Zsh so the framework cannot override them.

[[ -o interactive ]] || return

# Pass unmatched *, ?, and [...] tokens through unchanged instead of raising
# "no matches found".
unsetopt nomatch

# Treat ! and =command literally instead of applying Zsh-only expansions.
unsetopt bang_hist
unsetopt equals

# Use Bash pipeline/redirection behavior rather than Zsh's implicit tee-like
# MULTIOS behavior for: command >file | next-command.
unsetopt multios

# Allow pasted shell snippets containing comments at the interactive prompt.
setopt interactive_comments
