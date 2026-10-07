CZSH_RUNTIME_FEATURES_DIR="$HOME/.config/czsh/features/runtime"

for feature_file in "$CZSH_RUNTIME_FEATURES_DIR"/*.zsh(N-.); do
    source "$feature_file"
done
