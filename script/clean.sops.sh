#!/usr/bin/env -S bash -euo pipefail
# CLEAN FILTER
#   Encrypt sensitive data on commit using SOPS/AGE
# SETUP
#   git config --local filter.sops.clean 'script/clean.sops.sh %f'
#   git config --local filter.sops.required true
#   grep -qxF "*.env filter=sops diff=sops" .gitattributes 2>/dev/null || echo "*.env filter=sops diff=sops" >> .gitattributes
#   git config --get-regexp "\.sops\."
# REFERENCES
#   https://github.com/getsops/sops/issues/1137
#   https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
#   https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter

echo "[clean.sops.sh] Encrypting .env file... '$1'"

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

# Encrypt the input
sops --encrypt --filename-override "$1" /dev/stdin
