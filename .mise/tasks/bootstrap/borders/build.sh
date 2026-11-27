#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Build JankyBorders from qeesung's fork at the pinned commit"
#MISE env={JB_REV="f56533701a3ce0fae1801f2c11586a62098fe727"}
#MISE skip_if='test "$(cat "$HOME/.local/share/janky-borders/bin/.rev" 2>/dev/null)" = "$JB_REV"'
# JankyBorders from qeesung's fork, built at a pinned commit: upstream leaves outlines behind in Mission Control on
# macOS 27 (FelixKratz/JankyBorders#209). Moving the pin rebuilds it; a failed build keeps the old one.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init
is_macos || exit 0

jb="$HOME/.local/share/janky-borders"
if [ ! -d "$jb/.git" ]; then
  git clone -q https://github.com/qeesung/JankyBorders.git "$jb" || warn "clone JankyBorders"
fi
if [ -d "$jb/.git" ] && [ "$(cat "$jb/bin/.rev" 2> /dev/null)" != "$JB_REV" ]; then
  if git -C "$jb" fetch -q origin && git -C "$jb" checkout -q "$JB_REV" && make -C "$jb" -s > /dev/null; then
    echo "$JB_REV" > "$jb/bin/.rev"
    launchctl kickstart -k "gui/$(id -u)/dev.mise.borders" > /dev/null 2>&1 || true
  else
    warn "build JankyBorders"
  fi
fi
