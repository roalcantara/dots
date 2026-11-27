#!/usr/bin/env bash
#MISE hide=true
#MISE extends="bootstrap_step"
#MISE description="Verify SOPS-filtered files in the checkout remain encrypted"
. "${BASH_SOURCE%/*}/../bootstrap/_lib.sh"
set -euo pipefail

has_profile container || {
  echo "does not apply: profile is not container"
  exit 0
}

tmp_git=""
trap '[ -z "$tmp_git" ] || rm -rf "$tmp_git"' EXIT

attrs_out=""
if git -C "$DOTS_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  attrs_out="$(git -C "$DOTS_DIR" ls-files | git -C "$DOTS_DIR" check-attr --stdin filter)"
else
  # Local Docker builds use git archive (no .git dir); a throwaway bare git dir lets git check-attr read .gitattributes.
  tmp_git="$(mktemp -d)"
  git init -q --bare "$tmp_git"
  attrs_out="$(cd "$DOTS_DIR" && find . -type f | sed 's|^\./||' | git --git-dir="$tmp_git" --work-tree="$DOTS_DIR" check-attr --stdin filter)"
fi

checked=0
failed=0
while IFS= read -r line; do
  case "$line" in
    *": filter: sops")
      rel="${line%: filter: sops}"
      path="$DOTS_DIR/$rel"
      [ -f "$path" ] || continue
      checked=$((checked + 1))
      if ! grep -qF 'ENC[AES256_GCM,' "$path"; then
        echo "sops-encrypted: $rel is not SOPS-encrypted" >&2
        failed=1
      fi
      ;;
  esac
done <<< "$attrs_out"

if [ "$checked" -eq 0 ]; then
  echo "sops-encrypted: no filter=sops files found under $DOTS_DIR" >&2
  exit 1
fi
exit "$failed"
