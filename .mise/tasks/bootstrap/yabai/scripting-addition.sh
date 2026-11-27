#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Set up yabai's scripting addition (sudoers rule, boot argument)"
# After Homebrew: the sudoers rule for `yabai --load-sa` and the arm64e boot argument. `yb sa` only warns.
# ~/.local/bin is linked later (dotfiles), so call the repo copy.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
is_macos || exit 0
bootstrap_init

PATH="/opt/homebrew/bin:$PATH" "$DOTS_DIR/config/bin/yb" sa || true
