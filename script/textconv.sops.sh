#!/usr/bin/env -S bash -euo pipefail
# DIFF TEXTCONV
#   Show SOPS files decrypted in git diff and git log -p (diff.sops.textconv, for files with diff=sops).
#   Git passes one argument, a file path. The committed side is ciphertext and is decrypted here. The working-tree
#   side is already plain text, and a machine without the age key (CI, a clone made before the key) can't decrypt:
#   both are printed as they are, so git diff never fails or hangs.
#   NEVER set diff.sops.cachetextconv: git would store the decrypted text in refs/notes/textconv.
# SETUP
#   git config --local diff.sops.textconv script/textconv.sops.sh
#   git config --local diff.sops.cachetextconv false
# REFERENCES
#   https://git-scm.com/docs/gitattributes#_performing_text_diffs_of_binary_files
#   https://github.com/getsops/sops/issues/1137

set -euo pipefail

# The same key file as the filter scripts (on macOS, sops otherwise looks in ~/Library/Application Support).
AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$AGE_KEY_FILE}"

# git keeps the file's name in its temporary copy (…/git-blob-XXXXXX/a.env), so sops infers the same format it
# encrypted with.
sops --decrypt "$1" 2> /dev/null || cat "$1"
