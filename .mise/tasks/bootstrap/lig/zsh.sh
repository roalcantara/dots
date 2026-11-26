#!/usr/bin/env bash
#MISE description="Cache Lig's zsh integration on desktops where Lig is installed"
# Lig's cached zsh integration (config/zsh/opt/rc.d/lig.zsh), on desktops where Lig is installed.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

command -v lig > /dev/null || exit 0
mise -C "$DOTS_DIR" run zsh:lig || warn "zsh:lig"
