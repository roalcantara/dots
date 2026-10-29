#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 2: Inspect /origin/history.git for plaintext leaks ==="

cd /origin/history.git

echo "--- Recent commits in origin bare repository ---"
git log --stat main

echo "--- Checking for private key headers in git history ---"
# Check if any git blob contains private key headers
if git log -p main | grep -E "BEGIN [A-Z ]*PRIVATE KEY"; then
    echo "FAIL: Found plaintext private key header in history!"
    exit 1
else
    echo "PASS: No plaintext private key headers found in any git blob."
fi

echo "--- Inspecting commit diff ---"
git show main --stat

echo "--- Inspecting .mise-history/manifest.json ---"
git show main:.mise-history/manifest.json

echo "--- Inspecting tracked file blobs (sample: home/.ssh/id_ed25519) ---"
git show main:home/.ssh/id_ed25519 | head -n 10 || true

echo "=== Experiment 2: Inspection complete ==="
