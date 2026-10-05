_czsh_tool_report() {
    if [[ ${_czsh_report:-false} == true ]]; then
        print -r -- "[OK]   $1: $2"
        (( _czsh_tool_count += 1 ))
    fi
    return 0
}

_czsh_tool_error() {
    if [[ ${_czsh_report:-false} == true ]]; then
        print -ru2 -- "[FAIL] $1"
        (( _czsh_tool_failures += 1 ))
    fi
    return 0
}

_czsh_tool_path() {
    local tool_name="$1" tool_dir="$2"
    [[ -d "$tool_dir" ]] || return 1
    if [[ ${3:-prepend} == append ]]; then
        path+=("$tool_dir")
    else
        path=("$tool_dir" $path)
    fi
    typeset -gU path
    export PATH
    _czsh_tool_report "$tool_name" "$tool_dir"
}

_czsh_init_homebrew() {
    emulate -L zsh
    local brew_bin="" brew_dir="" brew_env="" candidate=""
    for candidate in \
        "${BREW_LOCATION:-}" "${commands[brew]:-}" \
        "$HOME/.linuxbrew/bin/brew" /opt/homebrew/bin/brew \
        /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            brew_bin="$candidate"
            break
        fi
    done
    [[ -n "$brew_bin" ]] || return 0
    brew_dir="${brew_bin:h}"
    if [[ ${_czsh_report:-false} == true || ${_CZSH_HOMEBREW_BIN:-} != "$brew_bin" || -z ${HOMEBREW_PREFIX:-} ]] ||
        (( ! ${path[(Ie)$brew_dir]} )); then
        if brew_env="$("$brew_bin" shellenv 2>/dev/null)" && eval "$brew_env"; then
            typeset -g _CZSH_HOMEBREW_BIN="$brew_bin"
        else
            _czsh_tool_error "Homebrew initialization failed: $brew_bin"
            return 0
        fi
    fi
    _czsh_tool_report Homebrew "$brew_bin"
}

_czsh_init_node() {
    emulate -L zsh
    local volta_home="${VOLTA_HOME:-$HOME/.volta}"
    local nvm_home="${NVM_DIR:-${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/nvm}}" nvm_script=""
    local fnm_bin="${commands[fnm]:-}" fnm_env="" candidate=""
    [[ -n "$nvm_home" ]] || nvm_home="$HOME/.nvm"
    local -a nvm_scripts=("$nvm_home/nvm.sh")
    if [[ -z ${NVM_DIR:-} ]]; then
        nvm_scripts+=("$HOME/.nvm/nvm.sh" "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh")
    fi

    if (( $+functions[nvm] )); then
        _czsh_tool_path nvm "${NVM_BIN:-}" || true
        return 0
    fi
    if [[ -z ${FNM_MULTISHELL_PATH:-} && -x "$volta_home/bin/volta" ]]; then
        export VOLTA_HOME="$volta_home"
        _czsh_tool_path Volta "$VOLTA_HOME/bin"
        return 0
    fi

    for candidate in \
        "$fnm_bin" "${FNM_DIR:-$HOME/.fnm}/fnm" \
        "${XDG_DATA_HOME:-$HOME/.local/share}/fnm/fnm" \
        "$HOME/Library/Application Support/fnm/fnm"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            fnm_bin="$candidate"
            break
        fi
    done
    if [[ -n "$fnm_bin" && -x "$fnm_bin" ]]; then
        _czsh_tool_path fnm "${fnm_bin:h}"
        if [[ -n ${FNM_MULTISHELL_PATH:-} ]] &&
            [[ ${_CZSH_FNM_READY:-} == "$FNM_MULTISHELL_PATH" || ${+functions[_fnm_autoload_hook]} == 1 ]]; then
            _czsh_tool_path 'fnm Node' "$FNM_MULTISHELL_PATH/bin" || true
            return 0
        fi
        if fnm_env="$("$fnm_bin" env --use-on-cd --shell zsh 2>/dev/null)" && eval "$fnm_env"; then
            typeset -g _CZSH_FNM_READY="${FNM_MULTISHELL_PATH:-}"
            return 0
        fi
        _czsh_tool_error "fnm initialization failed: $fnm_bin"
        return 0
    fi
    if [[ -n ${FNM_MULTISHELL_PATH:-} ]]; then
        _czsh_tool_path 'fnm Node' "$FNM_MULTISHELL_PATH/bin" || true
        _czsh_tool_error 'fnm environment is set but its executable was not found'
        return 0
    fi

    for candidate in "${nvm_scripts[@]}"; do
        if [[ -r "$candidate" ]]; then
            nvm_script="$candidate"
            nvm_home="${candidate:h}"
            break
        fi
    done
    if [[ -z "$nvm_script" && -n ${HOMEBREW_PREFIX:-} && -r "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
        nvm_script="$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    fi
    if [[ -n "$nvm_script" ]]; then
        export NVM_DIR="$nvm_home"
        if source "$nvm_script"; then
            _czsh_tool_report nvm "$nvm_script"
        else
            _czsh_tool_error "nvm initialization failed: $nvm_script"
        fi
    fi
}

_czsh_npm_prefix() {
    emulate -L zsh
    setopt extendedglob
    local prefix="${NPM_CONFIG_PREFIX:-${npm_config_prefix:-}}" line=""
    local npmrc="${NPM_CONFIG_USERCONFIG:-${npm_config_userconfig:-$HOME/.npmrc}}"
    local cache="$HOME/.config/czsh/state/npm-prefix"
    if [[ -z "$prefix" && -r "$npmrc" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ '^[[:space:]]*prefix[[:space:]]*=(.*)$' ]]; then
                prefix="${match[1]}"
            fi
        done < "$npmrc"
        prefix="${prefix##[[:space:]]#}"
        prefix="${prefix%%[[:space:]]#}"
        if [[ "$prefix" == \"*\" || "$prefix" == \'*\' ]]; then
            prefix="${prefix[2,-2]}"
        fi
        prefix="${prefix//\$\{HOME\}/$HOME}"
        [[ "$prefix" == '~/'* ]] && prefix="$HOME/${prefix#\~/}"
        if [[ "$prefix" != /* || "$prefix" == *'${'* ||
            "$prefix" == *\\* || "$prefix" == *';'* || "$prefix" == *'#'* ]]; then
            prefix=""
        fi
    fi
    [[ "$prefix" == '~/'* ]] && prefix="$HOME/${prefix#\~/}"
    [[ "$prefix" == /* ]] || prefix=""
    if [[ -z "$prefix" && -r "$cache" ]]; then
        IFS= read -r prefix < "$cache"
    fi
    [[ "$prefix" == /* && "$prefix" != *$'\n'* ]] || return 1
    print -r -- "$prefix"
}

_czsh_init_tools() {
    emulate -L zsh
    setopt extendedglob
    local _czsh_report="${1:-false}"
    local -i _czsh_tool_count=0 _czsh_tool_failures=0
    local prefix="" cache_dir="$HOME/.config/czsh/state" cache_file=""
    local pnpm_dir="" candidate=""

    if [[ -d "$HOME/.local/bin" ]]; then
        path=("$HOME/.local/bin" $path)
    fi
    _czsh_init_homebrew
    _czsh_tool_path Cargo "${CARGO_HOME:-$HOME/.cargo}/bin" || true
    _czsh_tool_path Bun "${BUN_INSTALL:-$HOME/.bun}/bin" || true
    _czsh_init_node

    for candidate in \
        "${PNPM_HOME:-}" "${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" \
        "$HOME/Library/pnpm"; do
        if [[ -n "$candidate" && -d "$candidate" ]]; then
            pnpm_dir="$candidate"
            break
        fi
    done
    if [[ -n "$pnpm_dir" ]]; then
        export PNPM_HOME="$pnpm_dir"
        _czsh_tool_path pnpm "$PNPM_HOME"
    fi

    if [[ "${2:-}" == refresh ]] && (( $+commands[npm] )); then
        if prefix="$(cd "$HOME" && command npm config get prefix 2>/dev/null)" &&
            [[ "$prefix" == /* && "$prefix" != *$'\n'* ]]; then
            if mkdir -p "$cache_dir" && cache_file="$(mktemp "$cache_dir/npm-prefix.XXXXXX")"; then
                if print -r -- "$prefix" > "$cache_file" && mv -f "$cache_file" "$cache_dir/npm-prefix"; then
                    :
                else
                    rm -f "$cache_file"
                    _czsh_tool_error "Could not cache npm's global prefix"
                fi
            else
                _czsh_tool_error "Could not create npm's global prefix cache"
            fi
        else
            prefix=""
            _czsh_tool_error "Could not read npm's global prefix"
        fi
    fi
    [[ -n "$prefix" ]] || prefix="$(_czsh_npm_prefix)"
    [[ -z "$prefix" ]] || _czsh_tool_path 'npm globals' "$prefix/bin" append || true
    _czsh_tool_path 'npm globals' "$HOME/.npm-global/bin" append || true
    typeset -gU path
    export PATH

    if [[ "$_czsh_report" == true && $_czsh_tool_count == 0 && $_czsh_tool_failures == 0 ]]; then
        print -r -- 'No supported tool installations found.'
    fi
    (( _czsh_tool_failures == 0 ))
}

_czsh_scan() {
    if (( $# )); then
        if [[ $# == 1 && ( "$1" == --help || "$1" == -h ) ]]; then
            print -r -- 'Usage: czsh scan'
            return 0
        fi
        print -ru2 -- 'Usage: czsh scan'
        return 2
    fi
    print -r -- 'CZSH tool environment scan'
    _czsh_init_tools true refresh
}

czsh() {
    if [[ ${1:-} == scan ]]; then
        shift
        _czsh_scan "$@"
    else
        command czsh "$@"
    fi
}

[[ ${CZSH_AUTO_DETECT_TOOLS:-true} == false ]] || _czsh_init_homebrew
