#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Repeat the brew bundle warning at the end of the bootstrap"
# Repeat the post-packages step's warning last, where it is seen (it scrolls away during the bootstrap). Always
# exits 0: a failed optional package must not fail the bootstrap here.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

failed_file="${XDG_STATE_HOME:-$HOME/.local/state}/dots/brew-bundle.failed"
[ -s "$failed_file" ] || exit 0
printf '\nbootstrap: brew bundle could not install: %s\n  retry: brew bundle install (log: %s)\n' \
  "$(cat "$failed_file")" "${failed_file%.failed}.log" >&2
