#!/usr/bin/env bash
#MISE description="Link ~/.config/homebrew into the repo so brew keeps its trust store there"
#MISE skip_if='test -e "$HOME/.config/homebrew" || test -L "$HOME/.config/homebrew"'
# brew keeps its tap trust store in $XDG_CONFIG_HOME/homebrew/trust.json (~/.homebrew without it). Shells set
# XDG_CONFIG_HOME, so use the same store here, through the ~/.config/homebrew link into config/homebrew. Packages
# run before dotfiles: make that link now (the one mise dotfiles makes), or brew creates a real folder dotfiles
# won't replace.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [ "$XDG_CONFIG_HOME" = "$HOME/.config" ] && [ ! -e "$HOME/.config/homebrew" ] && [ ! -L "$HOME/.config/homebrew" ] \
  && [ -d "$DOTS_DIR/config/homebrew" ]; then
  mkdir -p "$HOME/.config"
  ln -s ../.local/share/dots/config/homebrew "$HOME/.config/homebrew"
fi
