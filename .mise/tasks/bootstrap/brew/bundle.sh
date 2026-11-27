#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Install the Brewfile: the core group is fatal, the rest only warns"
# Homebrew and every user package. Runs after the apt prerequisites, in two stages: the core group (what the shell
# and git need) stops the bootstrap on failure; the rest of the Brewfile only warns, so one broken entry cannot
# skip the links, the login shell and the bootstrap task. CI or DOTS_STRICT makes the second stage fatal too.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export HOMEBREW_BUNDLE_FILE="${HOMEBREW_BUNDLE_FILE:-$DOTS_DIR/config/homebrew/Brewfile}"
bundle()
         {
           HOMEBREW_DOTS_PROFILE="$1" brew bundle install --no-upgrade
}

# 1. Core group: the shell and git need it, so a failure stops the bootstrap.
bundle container
if has_profile container; then
  brew cleanup --prune=all 2> /dev/null || true
  rm -rf "$HOME/.cache/Homebrew" 2> /dev/null || true
  exit 0
fi

# 2. Everything else: warn and carry on. The bootstrap task repeats the warning at its end.
state="${XDG_STATE_HOME:-$HOME/.local/state}/dots"
mkdir -p "$state"
rm -f "$state/brew-bundle.failed"
profile_list="$(printf '%s' "${usage_profile:-desktop}" | tr ' ' ',')"
if ! bundle "$profile_list" 2>&1 | tee "$state/brew-bundle.log"; then
  failed="$(sed -nE 's/^(Installing|Tapping) (.+) has failed!$/\2/p' "$state/brew-bundle.log" | sort -u | paste -sd ' ' -)"
  printf '%s\n' "${failed:-unknown (see the log)}" > "$state/brew-bundle.failed"
  if [ -n "${DOTS_STRICT:-}${CI:-}" ]; then
    echo "brew bundle failed: ${failed:-see $state/brew-bundle.log}" >&2
    exit 1
  fi
  printf '\nWARNING: brew bundle could not install: %s\n  log: %s\n  retry: brew bundle install\n\n' \
    "${failed:-unknown}" "$state/brew-bundle.log" >&2
fi
