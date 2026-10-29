#!/usr/bin/env bash
set -euo pipefail

echo "=== Experiment 7: Root-owned system files via sudo and bootstrap hooks ==="

CONFIG_DIR="${HOME}/.config/mise"
mkdir -p "${CONFIG_DIR}/conf.d"

MARKER_FILE="/tmp/hook-marker-spike.txt"
rm -f "${MARKER_FILE}"

cat << 'EOF' > "${CONFIG_DIR}/conf.d/spike-sys.toml"
[bootstrap.files."/etc/sudoers.d/spike"]
content = "vscode ALL=(ALL) NOPASSWD:ALL\n"
mode = "0440"
owner = "root"
group = "root"

[bootstrap.hooks]
post-packages = "touch /tmp/hook-marker-spike.txt"
EOF

echo "Running mise bootstrap --only files,packages --yes -v..."
mise bootstrap --only files,packages --yes -v

echo "--- Verifying /etc/sudoers.d/spike ---"
test -f /etc/sudoers.d/spike

FILE_STAT=$(stat -c "%a %U:%G" /etc/sudoers.d/spike)
echo "File permissions and ownership: ${FILE_STAT}"
test "${FILE_STAT}" = "440 root:root"
echo "PASS: /etc/sudoers.d/spike is mode 0440 and owned by root:root."

echo "Validating sudoers syntax via visudo:"
sudo visudo -cf /etc/sudoers.d/spike
echo "PASS: visudo syntax check passed."

echo "--- Verifying post-packages hook execution ---"
test -f "${MARKER_FILE}"
ls -l "${MARKER_FILE}"
echo "PASS: Hook post-packages executed successfully and created marker file."

echo "Working syntax recorded:"
echo '  [bootstrap.hooks]'
echo '  post-packages = "touch /tmp/hook-marker-spike.txt"'
# shellcheck disable=SC2016
echo '  (Note: Both `post-packages` and `"post-packages"` are valid TOML keys; `post_packages` is not recognized)'

echo "=== Experiment 7: Completed ==="
