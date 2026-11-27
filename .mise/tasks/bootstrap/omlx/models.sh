#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Download the oMLX models that are missing (macOS, once the app is installed by hand)"
#DOTS artifact=.omlx/models
# oMLX models (macOS, once the app is installed by hand): download only the missing ones.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init

if [ -d /Applications/oMLX.app ] && command -v hf > /dev/null; then
  for model in mlx-community/parakeet-tdt-0.6b-v3 Jundot/gemma-4-E2B-it-oQ4e-mtp \
    mlx-community/Qwen3-4B-Instruct-2507-4bit; do
    dir="$HOME/.omlx/models/$model"
    [ -f "$dir/config.json" ] || hf download "$model" --local-dir "$dir" || warn "oMLX model $model"
  done
fi
