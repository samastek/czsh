#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
budget_ms="${CZSH_STARTUP_BUDGET_MS:-150}"
smoke_home="$(mktemp -d "${TMPDIR:-/tmp}/czsh-bench.XXXXXX")"
results_file="$smoke_home/hyperfine.json"
trap 'rm -rf "$smoke_home"' EXIT

command -v hyperfine >/dev/null 2>&1 || {
  printf 'hyperfine is required; install it from packages/Brewfile or your package manager.\n' >&2
  exit 1
}

"$script_dir/prepare-smoke-home.sh" "$smoke_home" --full

printf 'Benchmarking interactive CZSH startup (budget: %s ms)...\n' "$budget_ms"
HOME="$smoke_home" ZDOTDIR="$smoke_home" TMUX='' hyperfine \
  --warmup 3 --runs 10 --export-json "$results_file" 'zsh -ic exit'

mean_ms="$(python3 - "$results_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    result = json.load(handle)["results"][0]
print(f'{result["mean"] * 1000:.2f}')
PY
)"

printf 'Mean startup: %s ms\n' "$mean_ms"
if awk -v mean="$mean_ms" -v budget="$budget_ms" 'BEGIN { exit !(mean > budget) }'; then
  printf 'Startup budget exceeded: %s ms > %s ms\n' "$mean_ms" "$budget_ms" >&2
  exit 1
fi
