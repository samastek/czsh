typeset -g _CZSH_INIT_CACHE_SOURCE="${${(%):-%x}:A}"

_czsh_cached_init() {
    emulate -L zsh
    local tool="$1"
    shift
    local init_code=""
    if (( $+functions[$tool] || $+aliases[$tool] )); then
        init_code="$(eval "${(q)tool} ${(j: :)${(q)@}}")" || return $?
        eval "$init_code"
        return $?
    fi
    local init_bin="$(whence -p "$tool")"
    [[ -n "$init_bin" ]] || return 0
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/czsh/init"
    local cache_file="$cache_dir/$tool.zsh" cached_key="" temp_file=""
    local -A binary_stat
    zmodload zsh/stat
    zstat -H binary_stat "$init_bin" || return $?
    local cache_key="# $ZSH_VERSION ${(q)${init_bin:A}} ${(j: :)${(q)@}}"
    cache_key+=" $binary_stat[device] $binary_stat[inode] $binary_stat[size] $binary_stat[mtime] $binary_stat[ctime]"
    if [[ "$tool" == zoxide ]]; then
        cache_key+=" ${(q)_ZO_ECHO} ${(q)_ZO_RESOLVE_SYMLINKS}"
    fi

    if [[ -r "$cache_file" && ! "$init_bin" -nt "$cache_file" &&
          ! "$_CZSH_INIT_CACHE_SOURCE" -nt "$cache_file" ]]; then
        IFS= read -r cached_key < "$cache_file"
        if [[ "$cached_key" == "$cache_key" ]]; then
            source "$cache_file"
            return $?
        fi
    fi

    init_code="$("$init_bin" "$@")" || return $?
    [[ -n "$init_code" ]] || return 0
    if command mkdir -m 700 -p "$cache_dir" 2>/dev/null &&
        temp_file="$(command mktemp "$cache_dir/$tool.XXXXXX" 2>/dev/null)"; then
        if print -rl -- "$cache_key" "$init_code" > "$temp_file" &&
            command mv -f "$temp_file" "$cache_file"; then
            :
        else
            command rm -f "$temp_file"
        fi
    fi
    eval "$init_code"
}
