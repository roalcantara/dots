#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Turn off VS Code Settings Sync for settings, keybindings and snippets"
# Settings Sync would merge the cloud copy back into the linked files (the repo is their source), so turn it off for
# settings, keybindings and snippets and leave it on for extensions, state and the rest. VS Code keeps these choices
# in its state database, not settings.json; a running VS Code reads them at start.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
is_macos || exit 0
bootstrap_init

command -v sqlite3 > /dev/null || exit 0
db="${DOTS_VSCODE_STATE:-$HOME/Library/Application Support/Code/User/globalStorage/state.vscdb}"
mkdir -p "$(dirname "$db")"
sqlite3 -cmd ".timeout 5000" "$db" "
CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB);
INSERT INTO ItemTable (key, value) VALUES
  ('sync.enable.settings', 'false'), ('sync.enable.keybindings', 'false'), ('sync.enable.snippets', 'false');
" || warn "VS Code Settings Sync"
