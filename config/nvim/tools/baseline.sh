#!/usr/bin/env bash
# Capture a comparable snapshot of Neovim's observable state.
#
#   tools/baseline.sh capture <label>   # write .tmp/baseline/<label>/
#   tools/baseline.sh diff <a> <b>      # diff two snapshots
#
# Snapshots are plain text and sorted, so `diff` output is meaningful.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${ROOT}/.tmp/baseline"
BASELINE_LUA="${ROOT}/tools/baseline"

capture() {
  local label="${1:?usage: baseline.sh capture <label>}"
  local out="${OUT_ROOT}/${label}"
  mkdir -p "$out"

  # 1. Startup errors. Any output here is a failure.
  nvim --headless +q >"${out}/startup-stderr.txt" 2>&1 || true

  # 2. Startup time: median of 3 runs, in ms.
  : >"${out}/startuptime-runs.txt"
  for _ in 1 2 3; do
    local log
    log="$(mktemp)"
    nvim --headless --startuptime "$log" +q >/dev/null 2>&1 || true
    awk '/NVIM STARTED/ { print $1 }' "$log" >>"${out}/startuptime-runs.txt"
    rm -f "$log"
  done
  sort -n "${out}/startuptime-runs.txt" | sed -n '2p' >"${out}/startuptime-median.txt"

  # 3. Keymaps: every mode, sorted "mode<TAB>lhs<TAB>desc".
  nvim --headless +"luafile ${BASELINE_LUA}/capture-keymaps.lua" +qa >"${out}/keymaps.tsv" 2>/dev/null || true

  # 4. Autocmds: sorted "group<TAB>event<TAB>pattern".
  nvim --headless +"luafile ${BASELINE_LUA}/capture-autocmds.lua" +qa >"${out}/autocmds.tsv" 2>/dev/null || true

  # 5. Loaded plugins, sorted.
  nvim --headless +"luafile ${BASELINE_LUA}/capture-plugins.lua" +qa >"${out}/plugins.txt" 2>/dev/null || true

  # 6. Eager-load contract: which core/ modules are in package.loaded at
  #    startup. Phase 4 shrinks this list; nothing should ever re-add to it.
  nvim --headless +"luafile ${BASELINE_LUA}/capture-eager-core.lua" +qa >"${out}/eager-core-modules.txt" 2>/dev/null || true

  # 7. Health (timestamps appear, so diffs are advisory only).
  nvim --headless -c 'checkhealth' -c 'w! '"${out}/checkhealth.txt" -c 'qa!' \
    >/dev/null 2>&1 || true

  echo "captured -> ${out}"
  echo "  startup median: $(cat "${out}/startuptime-median.txt") ms"
  echo "  keymaps:        $(wc -l <"${out}/keymaps.tsv" | tr -d ' ')"
  echo "  autocmds:       $(wc -l <"${out}/autocmds.tsv" | tr -d ' ')"
  echo "  eager core/:    $(wc -l <"${out}/eager-core-modules.txt" | tr -d ' ')"
}

diff_snapshots() {
  local a="${OUT_ROOT}/${1:?usage: baseline.sh diff <a> <b>}"
  local b="${OUT_ROOT}/${2:?usage: baseline.sh diff <a> <b>}"
  local rc=0
  for f in keymaps.tsv autocmds.tsv plugins.txt eager-core-modules.txt; do
    echo "=== $f ==="
    diff -u "${a}/${f}" "${b}/${f}" || rc=1
  done
  echo "=== startuptime median (ms) ==="
  echo "  ${1}: $(cat "${a}/startuptime-median.txt")"
  echo "  ${2}: $(cat "${b}/startuptime-median.txt")"
  return $rc
}

case "${1:-}" in
  capture) shift; capture "$@" ;;
  diff)    shift; diff_snapshots "$@" ;;
  *) echo "usage: baseline.sh {capture <label>|diff <a> <b>}" >&2; exit 2 ;;
esac
