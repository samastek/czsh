#!/usr/bin/env bash
# Idempotent helper primitives

: "${CZSH_COMPONENTS:=}"; : "${CZSH_COMPONENT_TIMES:=}"; CZSH_COMPONENTS=(${CZSH_COMPONENTS[@]:-}) CZSH_COMPONENT_TIMES=(${CZSH_COMPONENT_TIMES[@]:-})

ensure_dir() { mkdir -p -- "$@"; }

ensure_clone() {
  local repo=$1 dest=$2
  if [[ -d $dest/.git ]]; then
    (git -C "$dest" fetch --quiet && git -C "$dest" merge --ff-only FETCH_HEAD --quiet && logUpdated "$(basename "$dest")") || \
    (git -C "$dest" pull --rebase --autostash --quiet && logUpdated "$(basename "$dest")") || \
    logWarning "Update failed for $dest"
  else
    logInstalling "$(basename "$dest")"
    git clone --depth 1 --quiet "$repo" "$dest" && logInstalled "$(basename "$dest")" || logError "Clone failed: $repo"
  fi
}

ensure_symlink() { local target=$1 link=$2; ln -sf "$target" "$link"; }

timed() { # timed <label> <command...>
  local label=$1; shift
  local start=$(date +%s)
  "$@"; local rc=$?
  local end=$(date +%s)
  CZSH_COMPONENT_TIMES+=("$label:$((end-start)):$rc")
  return $rc
}

register_component() { # name function flag_variable(optional)
  CZSH_COMPONENTS+=("$1|$2|${3:-}")
}

run_registered_components() {
  local entry name fn flagvar flagval
  for entry in "${CZSH_COMPONENTS[@]}"; do
    IFS='|' read -r name fn flagvar <<<"$entry"
    if [[ -n $flagvar ]]; then
      flagval=${!flagvar:-false}
      if [[ $flagval != true ]]; then
        logInfo "Skipping $name (flag $flagvar not enabled)"; continue
      fi
    fi
    print_section "$name" "$GEAR" "$BLUE"
    timed "$name" "$fn"
  done
}
