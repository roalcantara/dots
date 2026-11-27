#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Install the repo's git filters"
# Runs on every profile, before any step that needs the filters (line endings, SOPS).
# A git archive checkout (local Docker build) has no .git directory, so there is no local git config to set.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

git -C "$DOTS_DIR" rev-parse --git-dir > /dev/null 2>&1 || exit 0
mise run -C "$DOTS_DIR" setup:git:filters || warn "setup:git:filters"
