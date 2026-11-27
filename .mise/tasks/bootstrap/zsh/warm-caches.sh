#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Warm the user shell caches so login shells start with clean stderr"
# Pre-initialize user shell caches (zimfw modules, completions) so login shells start with clean stderr.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
bootstrap_init

zsh -ic 'exit' > /dev/null 2>&1 || true
