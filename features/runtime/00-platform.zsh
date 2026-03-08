export CZSH_PLATFORM="linux"
case "$OSTYPE" in
    darwin*) export CZSH_PLATFORM="macos" ;;
    linux*) export CZSH_PLATFORM="linux" ;;
esac

if command -v batcat >/dev/null 2>&1; then
    export CZSH_BAT_BIN="batcat"
elif command -v bat >/dev/null 2>&1; then
    export CZSH_BAT_BIN="bat"
else
    export CZSH_BAT_BIN="cat"
fi