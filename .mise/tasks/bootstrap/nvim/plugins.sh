#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Restore the Neovim plugins from lazy-lock.json"
#MISE sources=["config/nvim/lazy-lock.json"]
# Restore (not sync) installs the lockfile's versions, so a rerun changes nothing; bounded so a network stall cannot
# hang an unattended run.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

[ -d "$HOME/.config/nvim" ] || exit 0
if command -v nvim > /dev/null; then
  limit=""
  if command -v timeout > /dev/null; then limit="timeout 600"; elif command -v gtimeout > /dev/null; then limit="gtimeout 600"; fi
  $limit nvim --headless "+Lazy! restore" +qa < /dev/null || warn "nvim Lazy restore"
fi
