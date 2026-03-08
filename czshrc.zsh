CZSH_RUNTIME_FEATURES_DIR="$HOME/.config/czsh/features/runtime"

mkdir -p "$CZSH_RUNTIME_FEATURES_DIR"

setopt nullglob
for feature_file in "$CZSH_RUNTIME_FEATURES_DIR"/*.zsh; do
    [ -f "$feature_file" ] && source "$feature_file"
done
unsetopt nullglob
