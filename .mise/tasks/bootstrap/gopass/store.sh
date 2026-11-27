#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Clone the gopass password store once the age identity is there"
#MISE skip_if='test -d "$HOME/.local/share/gopass/password-store/.git"'
# Cloned once ~/.config/gopass (linked to config/gopass, SOPS-decrypted) holds the age identity. HTTPS through the
# gh login (install runs `gh auth login`): the SSH config names GitHub `Host github`, so git@github.com has no key.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

store="$HOME/.local/share/gopass/password-store"
if command -v gopass > /dev/null && [ ! -d "$store/.git" ] && [ -d "$HOME/.config/gopass/age" ]; then
  git -c credential.helper= -c 'credential.https://github.com.helper=!gh auth git-credential' \
    clone https://github.com/roalcantara/pass-store.git "$store" || warn "gopass store clone"
fi
