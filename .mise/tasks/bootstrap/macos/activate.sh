#!/usr/bin/env bash
#MISE description="Set the screenshots folder, default apps and hotkeys, then restart the menu bar apps"
# mise writes preference values verbatim, and these paths need $HOME: the screenshots folder, the duti file
# (LaunchServices applies it a few seconds later), the Spotlight hotkey without a logout, then restart Dock, Finder
# and the menu bar so the rest shows. Runs on every bootstrap (a brief flicker when nothing changed) and never fails
# it. DOTS_ACTIVATE_SETTINGS only exists for test/integration/bootstrap/macos-defaults.spec.ts.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
is_macos || exit 0
bootstrap_init

defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots" > /dev/null 2>&1 || true
duti="$(command -v duti || echo /opt/homebrew/bin/duti)"
dutifile="${XDG_CONFIG_HOME:-$HOME/.config}/duti/defaults.duti"
"$duti" "$dutifile" > /dev/null 2>&1 || true
"${DOTS_ACTIVATE_SETTINGS:-/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings}" -u > /dev/null 2>&1 || true
killall Dock Finder SystemUIServer > /dev/null 2>&1 || true
