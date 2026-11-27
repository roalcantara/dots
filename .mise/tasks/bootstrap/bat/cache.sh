#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Build bat's theme cache from the themes vendored in config/bat/themes"
# bat loads the vendored themes (tokyonight_storm) only from its cache.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

command -v bat > /dev/null || exit 0
bat cache --build > /dev/null || warn "bat cache --build"
