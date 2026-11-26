#!/usr/bin/env bash
#MISE description="Point SwiftBar at ~/.config/swiftbar/plugins"
# SwiftBar draws the space strip (config/swiftbar/plugins/spaces.sh runs `yb bar`). Point it at the plugin folder
# before its first launch, so it never asks; mise writes defaults verbatim and this path needs $HOME.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
is_macos || exit 0
bootstrap_init

defaults write com.ameba.SwiftBar PluginDirectory -string "$HOME/.config/swiftbar/plugins" || true
defaults write com.ameba.SwiftBar SUHasLaunchedBefore -bool true || true
