#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Verify desktop- and dev-only bootstrap artifacts are absent in a container"
. "${BASH_SOURCE%/*}/../bootstrap/_lib.sh"
set -euo pipefail

has_profile container || {
  echo "does not apply: profile is not container"
  exit 0
}

steps_dir="$DOTS_DIR/.mise/tasks/bootstrap"
failed=0
while IFS= read -r step; do
  grep -qE '^has_profile (desktop|dev) \|\| exit 0$' "$step" || continue
  artifact="$(sed -nE 's/^#DOTS artifact=(.+)$/\1/p' "$step" | head -n 1)"
  if [ -z "$artifact" ]; then
    echo "profile-parts: ${step#"$DOTS_DIR"/} has no #DOTS artifact= header" >&2
    failed=1
    continue
  fi
  [ "$artifact" = "-" ] && continue
  target="$HOME/$artifact"
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "profile-parts: unexpected artifact $target (from ${step#"$DOTS_DIR"/})" >&2
    failed=1
  fi
done < <(find "$steps_dir" -type f -name '*.sh' | sort)
exit "$failed"
