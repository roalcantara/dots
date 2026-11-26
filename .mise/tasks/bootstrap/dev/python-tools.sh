#!/usr/bin/env bash
#MISE description="Install the Python 3.13 tools that have no wheels for the newest Python (dev only)"
# Python tools that need 3.13 (no wheels for the newest Python); the Brewfile's uv entries cannot pin it. dev only.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile dev || exit 0
bootstrap_init

for tool in graphifyy code-review-graph; do
  uv tool list 2> /dev/null | grep -q "^$tool " || uv tool install --python 3.13 "$tool" || warn "uv $tool"
done
