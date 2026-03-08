cheat() {
    if [ "$2" ]; then
        curl "https://cheat.sh/$1/$2+$3+$4+$5+$6+$7+$8+$9+$10"
    else
        curl "https://cheat.sh/$1"
    fi
}

speedtest() {
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
}

s() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo "No search term provided"
        return 1
    fi

    rg --line-number "$query" | \
        fzf --preview "$CZSH_BAT_BIN --style=numbers --color=always --highlight-line {2} {1}" \
            --delimiter : --preview-window=up:wrap
}

f() {
    find . -type f -print0 | fzf --read0 --preview "$CZSH_BAT_BIN --color=always {}" | xargs -0 file -b
}

glclone() {
    local token="${GITLAB_TOKEN:-${GITLAB_PRIVATE_TOKEN:-}}"
    local clone_dir="./gitlab_projects"
    local gitlab_url=""
    local group_url=""
    local clone_mode="ssh"
    local opt

    for opt in "$@"; do
        case "$opt" in
            -h|--help)
                cat <<'EOF'
Usage: glclone <group_url> [options]

Options:
  -h, --help              Show this help message and exit
  -t, --token <token>     GitLab access token
  -d, --clone-dir <dir>   Directory to clone repositories into
  -g, --gitlab-url <url>  Override GitLab instance URL
  --https                 Prefer HTTPS clone URLs over SSH

Environment:
  GITLAB_TOKEN or GITLAB_PRIVATE_TOKEN can be used instead of --token.

Examples:
  glclone https://gitlab.com/my-group
  glclone https://gitlab.com/my-group --token glpat-xxxx --clone-dir ~/src/gitlab
  glclone https://gitlab.example.com/group/subgroup --gitlab-url https://gitlab.example.com --https
EOF
                return 0
                ;;
        esac
    done

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--token)
                token="$2"
                shift 2
                ;;
            -d|--clone-dir)
                clone_dir="$2"
                shift 2
                ;;
            -g|--gitlab-url)
                gitlab_url="$2"
                shift 2
                ;;
            --https)
                clone_mode="https"
                shift
                ;;
            -h|--help)
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Run 'glclone --help' for usage."
                return 1
                ;;
            *)
                if [[ -z "$group_url" ]]; then
                    group_url="$1"
                else
                    echo "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$group_url" ]]; then
        echo "Usage: glclone <group_url> [options]"
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "glclone requires jq. Re-run install.sh or install jq manually."
        return 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "glclone requires git."
        return 1
    fi

    local parsed_url="${group_url#*://}"
    local detected_host="${parsed_url%%/*}"
    local group_path="${parsed_url#*/}"

    if [[ "$group_path" == "$parsed_url" || -z "$group_path" ]]; then
        echo "Invalid GitLab group URL: $group_url"
        return 1
    fi

    if [[ -z "$gitlab_url" ]]; then
        gitlab_url="${group_url%%://*}"
        if [[ "$group_url" == http://* ]]; then
            gitlab_url="http://$detected_host"
        else
            gitlab_url="https://$detected_host"
        fi
    fi

    local api_base="${gitlab_url%/}/api/v4"
    local target_root="$clone_dir"
    mkdir -p "$target_root" || return 1

    local total_projects=0
    local successful_clones=0
    local failed_clones=0
    local skipped_projects=0

    local -a auth_header=()
    if [[ -n "$token" ]]; then
        auth_header=(-H "PRIVATE-TOKEN: $token")
    fi

    _glclone_urlencode() {
        printf '%s' "$1" | jq -sRr @uri
    }

    _glclone_api_get() {
        local endpoint="$1"
        curl -fsSL "${auth_header[@]}" "$api_base/$endpoint"
    }

    _glclone_api_get_paginated() {
        local endpoint="$1"
        local page=1
        local count=0
        local response=""
        local combined='[]'
        local separator='?'
        local got_any=0

        if [[ "$endpoint" == *\?* ]]; then
            separator='&'
        fi

        while true; do
            response="$(_glclone_api_get "${endpoint}${separator}per_page=100&page=$page")" || {
                if [[ $got_any -eq 0 ]]; then
                    return 1
                fi
                break
            }

            got_any=1
            combined="$(printf '%s\n%s\n' "$combined" "$response" | jq -cs '.[0] + .[1]')"
            count="$(printf '%s' "$response" | jq 'length')"

            if [[ "$count" -lt 100 ]]; then
                break
            fi

            ((page++))
        done

        printf '%s' "$combined"
    }

    _glclone_clone_repo() {
        local project_json="$1"
        local relative_path="$2"
        local repo_name clone_url repo_dir repo_namespace

        repo_name="$(printf '%s' "$project_json" | jq -r '.name')"
        repo_namespace="$(printf '%s' "$project_json" | jq -r '.path_with_namespace')"

        if [[ "$clone_mode" == "https" ]]; then
            clone_url="$(printf '%s' "$project_json" | jq -r '.http_url_to_repo')"
        else
            clone_url="$(printf '%s' "$project_json" | jq -r '.ssh_url_to_repo // .http_url_to_repo')"
            if [[ "$clone_url" == "null" || -z "$clone_url" ]]; then
                clone_url="$(printf '%s' "$project_json" | jq -r '.http_url_to_repo')"
            fi
        fi

        repo_dir="$target_root/$relative_path/$repo_name"
        mkdir -p "$(dirname "$repo_dir")" || return 1

        if [[ -d "$repo_dir/.git" ]]; then
            echo "Skipping $repo_namespace (already exists)"
            ((skipped_projects++))
            return 0
        fi

        echo "Cloning $repo_namespace"
        if git clone "$clone_url" "$repo_dir"; then
            ((successful_clones++))
            return 0
        fi

        ((failed_clones++))
        return 1
    }

    _glclone_process_group() {
        local current_group_path="$1"
        local parent_path="$2"
        local encoded_group group_json group_name full_path current_path projects_json subgroups_json
        local project subgroup subgroup_path

        encoded_group="$(_glclone_urlencode "$current_group_path")"
        group_json="$(_glclone_api_get "groups/$encoded_group")" || {
            echo "Failed to fetch group: $current_group_path"
            return 1
        }

        group_name="$(printf '%s' "$group_json" | jq -r '.path')"
        full_path="$(printf '%s' "$group_json" | jq -r '.full_path')"
        current_path="$group_name"
        if [[ -n "$parent_path" ]]; then
            current_path="$parent_path/$group_name"
        fi

        echo
        echo "Processing group: $full_path"

        projects_json="$(_glclone_api_get_paginated "groups/$encoded_group/projects?include_subgroups=false")" || projects_json='[]'
        while IFS= read -r project; do
            [[ -z "$project" ]] && continue
            ((total_projects++))
            _glclone_clone_repo "$project" "$current_path"
        done < <(printf '%s' "$projects_json" | jq -c '.[]')

        subgroups_json="$(_glclone_api_get_paginated "groups/$encoded_group/subgroups")" || subgroups_json='[]'
        while IFS= read -r subgroup; do
            [[ -z "$subgroup" ]] && continue
            subgroup_path="$(printf '%s' "$subgroup" | jq -r '.full_path')"
            _glclone_process_group "$subgroup_path" "$current_path"
        done < <(printf '%s' "$subgroups_json" | jq -c '.[]')
    }

    echo "GitLab URL: $gitlab_url"
    echo "Group URL: $group_url"
    echo "Clone directory: $target_root"
    echo "Auth token: $([[ -n "$token" ]] && echo provided || echo not-provided)"

    if ! _glclone_process_group "$group_path" ""; then
        return 1
    fi

    echo
    echo "Clone Summary:"
    echo "  Total projects: $total_projects"
    echo "  Successful clones: $successful_clones"
    echo "  Failed clones: $failed_clones"
    echo "  Skipped projects: $skipped_projects"

    [[ $failed_clones -eq 0 ]]
}