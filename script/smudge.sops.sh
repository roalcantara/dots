#!/usr/bin/env -S bash -euo pipefail
# SMUDGE FILTER
#   Decrypt sensitive data on checkout using SOPS/AGE
# SETUP
#   git config --local filter.sops.smudge script/smudge.sops.sh
#   git config --local filter.sops.required true
#   grep -qxF "*.env filter=sops diff=sops" .gitattributes 2>/dev/null || echo "*.env filter=sops diff=sops" >> .gitattributes
#   git config --get-regexp "\.sops\."
# REFERENCES
#   https://github.com/getsops/sops/issues/1137
#   https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
#   https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"   # Get the script directory
cd "${scriptDir}/.." || exit 1                                                  # Change to the repository root
sops --decrypt "$1"                                                             # Decrypt the input
