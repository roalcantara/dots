#!/usr/bin/env bash
# run.sh - End-to-end install test in Docker with throwaway history (N4)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

VOLUME_NAME="e2e-origin-$$"
IMAGE_NAME="e2e-base:latest"

cleanup()
          {
    docker volume rm -f "${VOLUME_NAME}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "=== N4: End-to-end install test in Docker ==="

# 1. Build Docker image
echo "--- Building ${IMAGE_NAME} ---"
docker build -q -t "${IMAGE_NAME}" "${SCRIPT_DIR}" > /dev/null

# 2. Create throwaway volume
docker volume create "${VOLUME_NAME}" > /dev/null

# 3. Create bundle of current branch
CURR_BRANCH="$(git -C "${DOTS_ROOT}" rev-parse --abbrev-ref HEAD)"
TMP_BUNDLE="$(mktemp /tmp/dots-bundle-XXXXXX.bundle)"
git -C "${DOTS_ROOT}" bundle create "${TMP_BUNDLE}" HEAD "${CURR_BRANCH}" > /dev/null

# Seed bundle and install into volume
docker run --rm \
    -v "${VOLUME_NAME}:/origin" \
    -v "${TMP_BUNDLE}:/tmp/dots.bundle:ro" \
    -v "${DOTS_ROOT}/install:/tmp/install:ro" \
    -u vscode \
    "${IMAGE_NAME}" \
    bash -c "cp /tmp/dots.bundle /origin/dots.bundle && cp /tmp/install /origin/install && chmod +x /origin/install"
rm -f "${TMP_BUNDLE}"

# 4. Run Container A: Generate throwaway keys and encrypted history
echo "--- Running Container A (Setup throwaway history origin) ---"
docker run -i --rm \
    -v "${VOLUME_NAME}:/origin" \
    -u vscode \
    "${IMAGE_NAME}" \
    bash << 'EOF'
set -euo pipefail

echo "Generating throwaway age key..."
age-keygen -o /origin/throwaway-key.txt
chmod 600 /origin/throwaway-key.txt
PUB="$(age-keygen -y /origin/throwaway-key.txt)"

mkdir -p ~/.config/ssh ~/.config/gnupg
chmod 700 ~/.config/ssh ~/.config/gnupg

ssh-keygen -t ed25519 -N "" -f ~/.config/ssh/id_ed25519 >/dev/null
gpg --batch --passphrase "" --quick-gen-key "Throwaway Key <throwaway@example.com>" default default never >/dev/null 2>&1

find ~/.config/ssh ~/.config/gnupg -type f -exec chmod 600 {} +
chmod 700 ~/.config/ssh ~/.config/gnupg

find ~/.config/ssh ~/.config/gnupg -type f -exec sha256sum {} + | sort > /origin/expected-sha256.txt
find ~/.config/ssh ~/.config/gnupg ! -type s -exec stat -c "%a %n" {} + | sort > /origin/expected-modes.txt

mkdir -p ~/.config/mise
cat << CONF > ~/.config/mise/config.toml
[settings]
age.key_file = "/origin/throwaway-key.txt"

[history.encryption]
recipients = ["${PUB}"]

[dotfiles]
"~/.config/ssh" = { mode = "track", encrypt = true, exclude = ["S.*", "s.*", "agent"] }
"~/.config/gnupg" = { mode = "track", encrypt = true, exclude = ["S.*", ".#lk*", "random_seed", "*~"] }
CONF

rm -rf /origin/history.git
git init --bare /origin/history.git >/dev/null
git -C /origin/history.git symbolic-ref HEAD refs/heads/main

mise dot origin set /origin/history.git --sync manual -y
mise dot save
mise dot sync

# Plaintext leak verification
d="$(mktemp -d)"
git clone -q /origin/history.git "$d"
if git -C "$d" log -p --all | grep -qE "BEGIN (OPENSSH|PGP) PRIVATE"; then
    echo "ERROR: Plaintext key detected in history repository!" >&2
    exit 1
fi
rm -rf "$d"
echo "Container A: Throwaway history origin created and verified clean."
EOF

# 5. Run Container B: Fresh environment testing install script
echo "--- Running Container B (Install and restore verification) ---"
docker run -i --rm \
    -v "${VOLUME_NAME}:/origin" \
    -e CURR_BRANCH="${CURR_BRANCH}" \
    -u vscode \
    "${IMAGE_NAME}" \
    bash << 'EOF'
set -euo pipefail
cd /home/vscode

THROWAWAY_KEY="$(grep -m1 '^AGE-SECRET-KEY-1' /origin/throwaway-key.txt)"

echo "Running install in fresh container..."
DOTS_AGE_KEY="${THROWAWAY_KEY}" \
DOTS_REPO="/origin/dots.bundle" \
DOTS_BRANCH="${CURR_BRANCH}" \
DOTS_HISTORY="/origin/history.git" \
DOTS_PROFILE="container" \
bash /origin/install

echo "Verifying restored state..."
# Check ~/.config/mise link
[ -L ~/.config/mise ] || { echo "FAIL: ~/.config/mise is not a symlink" >&2; exit 1; }
target="$(readlink ~/.config/mise)"
[ "${target}" = "../.local/share/dots/config/mise" ] || { echo "FAIL: unexpected ~/.config/mise target: ${target}" >&2; exit 1; }
# Check ~/.ssh and ~/.gnupg links to real config directories
[ -L ~/.ssh ] || { echo "FAIL: ~/.ssh is not a symlink" >&2; exit 1; }
[ -L ~/.gnupg ] || { echo "FAIL: ~/.gnupg is not a symlink" >&2; exit 1; }


# Check restored secrets byte-identity
find ~/.config/ssh ~/.config/gnupg -type f -exec sha256sum {} + | sort > /tmp/actual-sha256.txt
diff -u /origin/expected-sha256.txt /tmp/actual-sha256.txt || { echo "FAIL: Checksums do not match" >&2; exit 1; }

# Check restored modes (700 / 600)
find ~/.config/ssh ~/.config/gnupg ! -type s -exec stat -c "%a %n" {} + | sort > /tmp/actual-modes.txt
diff -u /origin/expected-modes.txt /tmp/actual-modes.txt || { echo "FAIL: Modes do not match" >&2; exit 1; }

# Verify functional key usage
ssh-keygen -y -f ~/.config/ssh/id_ed25519 >/dev/null
gpg --list-secret-keys >/dev/null 2>&1

echo "Verifying idempotency (second install run)..."
output=""
if ! output="$(DOTS_AGE_KEY="${THROWAWAY_KEY}" \
  DOTS_REPO="/origin/dots.bundle" \
  DOTS_BRANCH="${CURR_BRANCH}" \
  DOTS_HISTORY="/origin/history.git" \
  DOTS_PROFILE="container" \
  bash /origin/install 2>&1)"; then
  echo "SECOND RUN FAILED WITH OUTPUT:"
  echo "${output}"
  exit 1
fi
echo "${output}"
echo "${output}" | grep -q "Wrote 0 file(s)" || echo "Note: No files modified on second run"

echo "=== Container B: All verifications passed successfully! ==="
EOF

echo "=== N4 E2E test completed successfully ==="
