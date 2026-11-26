#!/usr/bin/env bash
#MISE description="Install the repo's git filters"
# Runs on every profile, before any step that needs the filters (line endings, SOPS).
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

mise run -C "$DOTS_DIR" setup:git:filters || warn "setup:git:filters"
