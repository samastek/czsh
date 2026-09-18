# Intentionally do not drain the terminal input buffer from a prompt hook.
# The former CPR workaround consumed arbitrary pending bytes and could corrupt
# pasted commands or interactive pipelines. Safe command-line compatibility
# options are applied after Oh My Zsh in features/post/05-shell-behavior.zsh.
