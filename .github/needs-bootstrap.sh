#!/usr/bin/env bash
# Reads changed paths, one per line, on stdin.
# Exits 0 when any path is outside docs/** and is not *.md; exits 1 otherwise (including empty input).
set -euo pipefail

while IFS= read -r path; do
  [ -n "$path" ] || continue
  case "$path" in
    docs/* | *.md) continue ;;
    *) exit 0 ;;
  esac
done
exit 1
