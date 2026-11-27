#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Install the repo's git hooks (desktop only)"
#DOTS artifact=-
# Hooks are a desktop concern; containers only get the filters.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

mise run -C "$DOTS_DIR" setup:hooks || warn "setup:hooks"
