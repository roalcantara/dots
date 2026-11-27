#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Install the Neovim providers (npm and gem)"
# Neovim's providers, when the config is linked and the runtime is there.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

[ -d "$HOME/.config/nvim" ] || exit 0
if command -v npm > /dev/null && ! npm ls -g neovim > /dev/null 2>&1; then
  npm install -g neovim || warn "npm neovim"
fi
if command -v gem > /dev/null && ! gem list -i neovim > /dev/null 2>&1; then
  gem install neovim || warn "gem neovim"
fi
