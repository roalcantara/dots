#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Warn when a real ~/.gitconfig overrides the dots git config"
# dots owns git's config in ~/.config/git/config, and git reads ~/.gitconfig after it, so anything there wins. Tools
# write it unasked (`gh auth setup-git` once pinned a since-removed mise gh there, and every https push then asked for a
# password). Only warns: merging it into config/git/config is the owner's call.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
validate_profile

if [ -e "$HOME/.gitconfig" ]; then
  echo "bootstrap: ~/.gitconfig overrides the dots git config (~/.config/git/config); merge what you need into config/git/config, then move it aside" >&2
fi
