#!/usr/bin/env -S bash -euo pipefail
# CLEAN FILTER
#   Encrypt sensitive data on commit using SOPS/AGE.
#   When plaintext is unchanged, returns the existing encrypted blob so Git
#   does not see the file as modified (SOPS encryption is non-deterministic).
# SETUP
#   git config --local filter.sops.clean 'script/clean.sops.sh %f'
#   git config --local filter.sops.required true
#   grep -qxF "*.env filter=sops diff=sops" .gitattributes 2>/dev/null || echo "*.env filter=sops diff=sops" >> .gitattributes
#   git config --get-regexp "\.sops\."
# REFERENCES
#   https://github.com/getsops/sops/issues/1137
#   https://github.com/FiloSottile/age/discussions/507
#   https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
#   https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter

set -euo pipefail

# Get script directory and change to repository root
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${scriptDir}/.." || exit 1

# Validate AGE key exists
AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "ERROR: AGE key file not found at $AGE_KEY_FILE" >&2
    echo "Please ensure AGE keys are properly configured." >&2
    exit 1
fi

# Check if age command is available
if ! command -v age >/dev/null 2>&1; then
    echo "ERROR: age command not found. Please install age." >&2
    exit 1
fi

# Validate SOPS configuration
if [ ! -f ".sops.yaml" ]; then
    echo "ERROR: SOPS configuration file .sops.yaml not found" >&2
    exit 1
fi

# Check if sops command is available
if ! command -v sops >/dev/null 2>&1; then
    echo "ERROR: sops command not found. Please install sops." >&2
    exit 1
fi

path="$1"
tmpdir=""
wt_file=""
enc_file=""
dec_file=""

cleanup() {
    [ -n "$tmpdir" ] && [ -d "$tmpdir" ] && rm -rf "$tmpdir"
}
trap cleanup EXIT

tmpdir="$(mktemp -d)"
wt_file="${tmpdir}/wt"
enc_file="${tmpdir}/enc"
dec_file="${tmpdir}/dec"

# Buffer working tree content (stdin)
cat > "$wt_file"

# New file: not in index → encrypt and output
if ! git show ":$path" > "$enc_file" 2>/dev/null; then
    sops --encrypt --filename-override "$path" "$wt_file"
    exit 0
fi

# Decrypt index blob for comparison
if ! sops --decrypt --filename-override "$path" "$enc_file" > "$dec_file" 2>/dev/null; then
    echo "ERROR: Could not decrypt index blob for $path; re-encrypting" >&2
    sops --encrypt --filename-override "$path" "$wt_file"
    exit 0
fi

# Hash both plaintexts
if command -v sha256sum >/dev/null 2>&1; then
    hash_index="$(sha256sum < "$dec_file" | cut -d' ' -f1)"
    hash_wt="$(sha256sum < "$wt_file" | cut -d' ' -f1)"
else
    hash_index="$(shasum -a 256 < "$dec_file" | cut -d' ' -f1)"
    hash_wt="$(shasum -a 256 < "$wt_file" | cut -d' ' -f1)"
fi

if [ "$hash_index" = "$hash_wt" ]; then
    # Unchanged: return existing encrypted blob so Git does not see a modification
    cat "$enc_file"
else
    sops --encrypt --filename-override "$path" "$wt_file"
fi
