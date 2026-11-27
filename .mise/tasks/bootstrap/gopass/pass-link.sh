#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Link ~/.local/bin/pass to gopass, never replacing a real pass"
#DOTS artifact=.local/bin/pass
# gopass is a drop-in for pass: tools that call `pass` (fnox's password-store provider, editor plugins) get gopass.
# Homebrew's gopass, from the prefix `brew shellenv` exported in bootstrap_init (bin/gopass follows upgrades); else
# any gopass on PATH. Never replaces a real pass: only creates or refreshes the link in ~/.local/bin.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

gp="${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/gopass}"
[ -n "$gp" ] && [ -x "$gp" ] || gp="$(command -v gopass || true)"
link="$HOME/.local/bin/pass"
if [ -n "$gp" ] && {
                     [ -L "$link" ] || ! command -v pass > /dev/null
}; then
  mkdir -p "${link%/*}" && ln -sfn "$gp" "$link" || warn "pass link"
fi
