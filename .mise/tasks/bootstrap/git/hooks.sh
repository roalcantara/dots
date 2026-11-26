#!/usr/bin/env bash
#MISE description="Install the repo's git hooks (desktop only)"
# Hooks are a desktop concern; containers only get the filters.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

mise run -C "$DOTS_DIR" setup:hooks || warn "setup:hooks"
