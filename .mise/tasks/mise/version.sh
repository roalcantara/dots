#!/usr/bin/env bash
#MISE description="List mise version pins; --check fails on drift, --sync rewrites them to this Mac's version"
#USAGE flag "--check" help="Exit 1 when any pin differs from this Mac's mise"
#USAGE flag "--sync" help="Rewrite every pin to this Mac's mise (macOS only)"
# This Mac is the reference: CI installs no mise of its own, so every committed pin must match it.
set -euo pipefail

dots="${DOTS_DIR:-$HOME/.local/share/dots}"
local_version="${DOTS_MISE_VERSION:-$(mise --version | awk '{print $1}')}"
local_version="${local_version#v}"
uname_s="${DOTS_UNAME:-$(uname -s)}"
pattern='MISE_VERSION="?v?[0-9]{4}\.[0-9]+\.[0-9]+'

# mise sets usage_check/usage_sync from #USAGE; accept the flags in argv too, so the spec can run the file directly.
check="${usage_check:-}"
sync="${usage_sync:-}"
for arg in "$@"; do
  case "$arg" in
    --check) check=true ;;
    --sync) sync=true ;;
    *)
      echo "mise:version: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done
if [ -n "$check" ] && [ -n "$sync" ]; then
  echo "mise:version: --check and --sync are mutually exclusive" >&2
  exit 2
fi

hits="$(mktemp)"
trap 'rm -f "$hits"' EXIT
# Pins are found by pattern, so a new pin site is covered. Code examples under docs/ and the vendored KB
# snapshot are not pins for this repo: syncing them would rewrite prose (and this plan).
git -C "$dots" grep -n -E "$pattern" -- ':(exclude)docs/**' ':(exclude)config/kodexb/**' > "$hits" 2> /dev/null || true
if [ ! -s "$hits" ]; then
  echo "mise:version: no ${pattern%%=*} pins under $dots" >&2
  exit 0
fi

# A pin is the version token after MISE_VERSION=, with the v prefix when the file writes one.
pin_of()
         {
  printf '%s\n' "$1" | sed -nE 's/.*MISE_VERSION="?(v?[0-9]{4}\.[0-9]+\.[0-9]+).*/\1/p'
}

drift=0
if [ -z "$sync" ]; then
  while IFS= read -r hit; do
    file="${hit%%:*}"
    rest="${hit#*:}"
    line="${rest%%:*}"
    pin="$(pin_of "${rest#*:}")"
    printf '%s:%s\t%s\t%s\n' "$file" "$line" "$pin" "$local_version"
    [ "${pin#v}" = "$local_version" ] && continue
    drift=$((drift + 1))
    [ -z "$check" ] || echo "mise:version: $file:$line has $pin, this Mac runs $local_version" >&2
  done < "$hits"
fi

if [ -n "$check" ] && [ "$drift" -gt 0 ]; then
  echo "mise:version: $drift pin(s) differ; run: mise run mise:version --sync" >&2
  exit 1
fi

if [ -n "$sync" ]; then
  if [ "$uname_s" != "Darwin" ]; then
    echo "mise:version: run --sync on macOS (this Mac's mise is the reference)" >&2
    exit 1
  fi
  while IFS= read -r file; do
    exprs=()
    while IFS= read -r hit; do
      [ "${hit%%:*}" = "$file" ] || continue
      rest="${hit#*:}"
      line="${rest%%:*}"
      pin="$(pin_of "${rest#*:}")"
      [ "${pin#v}" != "$local_version" ] || continue
      prefix=""
      [ "${pin#v}" = "$pin" ] || prefix="v"
      new="${prefix}${local_version}"
      old_re="${pin//./\\.}"
      exprs+=(-e "${line}s/${old_re}/${new}/")
      echo "mise:version: $file:$line $pin -> $new"
    done < "$hits"
    [ "${#exprs[@]}" -gt 0 ] || continue
    tmp="$(mktemp)"
    sed "${exprs[@]}" "$dots/$file" > "$tmp"
    cat "$tmp" > "$dots/$file"
    rm -f "$tmp"
  done < <(cut -d: -f1 "$hits" | sort -u)
fi
