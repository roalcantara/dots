#!/usr/bin/env bash
#MISE description="Move app-written VS Code and Karabiner files aside before the dots links"
# A link never replaces a real file, and VS Code (or Settings Sync) and Karabiner-Elements write real ones on first
# launch. Move them aside, never delete, so the links apply. Also runs before mise dot apply.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
is_macos || exit 0
bootstrap_init

user="${DOTS_VSCODE_USER:-$HOME/Library/Application Support/Code/User}"
mkdir -p "$user"
stamp="$(date +%Y%m%d%H%M%S)"
for p in "$user/settings.json" "$user/keybindings.json" "$user/snippets" "$HOME/.config/karabiner"; do
  if [ -e "$p" ] && [ ! -L "$p" ]; then
    mv "$p" "$p.pre-dots-$stamp"
    echo "bootstrap: moved $p to $p.pre-dots-$stamp; dots links it to the repo" >&2
  fi
done
