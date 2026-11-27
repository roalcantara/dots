#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Clone the kb Raycast extension and say what bootstrap cannot do for tiling"
# Tiling (docs/TILING.md): clone the kb Raycast extension (its yabai strip and Hotkeys command), and say what
# bootstrap cannot do itself. [bootstrap.repos] has no os key, so the clone lives here.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile desktop || exit 0
bootstrap_init
is_macos || exit 0

kb="$HOME/Work/kb"
if [ ! -d "$kb" ]; then
  git clone git@github.com:roalcantara/kb-raycast.git "$kb" || warn "clone kb-raycast"
fi
tiling_hint=false
case "$("${DOTS_CSRUTIL:-csrutil}" status 2> /dev/null)" in
  *"status: enabled"*)
    echo "bootstrap: SIP is fully on; yabai's scripting addition needs it partly off. In Recovery: csrutil enable --without fs --without debug --without nvram" >&2
    tiling_hint=true
    ;;
esac
if ! "${DOTS_YABAI:-/opt/homebrew/bin/yabai}" -m query --spaces > /dev/null 2>&1; then
  echo "bootstrap: yabai is not answering; grant it Accessibility (System Settings > Privacy & Security)" >&2
  tiling_hint=true
fi
if $tiling_hint; then
  echo "bootstrap: tiling setup steps: docs/TILING.md" >&2
fi
