#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Install Homebrew when it is missing (asks for sudo on the terminal)"
#MISE raw=true
#MISE skip_if='command -v brew >/dev/null || test -x /opt/homebrew/bin/brew || test -x /home/linuxbrew/.linuxbrew/bin/brew'
# Homebrew, once. mise skips this when any brew is already there, so it never reinstalls on a normal bootstrap.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

# The installer runs sudo without prompting under NONINTERACTIVE=1, so it needs a sudo ticket already. Linux has
# one from the apt packages; macOS has no earlier sudo step, so ask here, on the terminal.
if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2> /dev/null; then
  if (: < /dev/tty) 2> /dev/null; then
    echo "Homebrew needs administrator access to create its prefix; enter your password:" >&2
    # shellcheck disable=SC2024 # the redirect is the point: sudo's own stdin, not a file sudo would read
    sudo -v < /dev/tty || {
      echo "bootstrap: sudo failed; Homebrew was not installed" >&2
      exit 1
    }
  else
    echo "bootstrap: Homebrew needs sudo and there is no terminal to ask on: run 'sudo -v', then mise bootstrap" >&2
    exit 1
  fi
fi
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
