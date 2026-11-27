#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Verify the container Brewfile group is installed and on PATH in a login zsh"
. "${BASH_SOURCE%/*}/../bootstrap/_lib.sh"
set -euo pipefail

has_profile container || {
  echo "does not apply: profile is not container"
  exit 0
}

brewfile="$DOTS_DIR/config/homebrew/Brewfile"
# Run inside a login zsh so PATH reflects the user's real shell configuration (brew shellenv).
zsh -lic '
  set -euo pipefail
  brewfile="$1"
  command -v brew >/dev/null 2>&1 || { echo "container-tools: brew not found on PATH in login zsh" >&2; exit 1; }
  HOMEBREW_DOTS_PROFILE=container brew bundle check --file "$brewfile"
  prefix="$(brew --prefix 2>/dev/null || true)"
  if [ -n "$prefix" ] && [ -d "$prefix/opt" ]; then
    while IFS= read -r formula; do
      [ -n "$formula" ] || continue
      for bin in "$prefix/opt/$formula/bin/"*(N); do
        [ -x "$bin" ] || continue
        name="${bin##*/}"
        if ! command -v "$name" >/dev/null 2>&1; then
          echo "container-tools: $name (from $formula) not found on PATH in login zsh" >&2
          exit 1
        fi
      done
    done < <(HOMEBREW_DOTS_PROFILE=container brew bundle list --formula --file "$brewfile")
  fi
' -- "$brewfile"
