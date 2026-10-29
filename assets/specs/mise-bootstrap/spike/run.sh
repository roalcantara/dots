#!/usr/bin/env bash
# run.sh - Orchestrate reproducible spike experiments in Docker
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

EXPERIMENT="${1:-all}"
VOLUME_NAME="spike-origin"
IMAGE_NAME="spike-base:latest"

echo "=== Mise Bootstrap Spike Orchestrator ==="
echo "Target: Experiment ${EXPERIMENT}"
echo "Dots Root: ${DOTS_ROOT}"

# 1. Build spike docker image if needed
echo "--- Ensuring ${IMAGE_NAME} is built ---"
docker build -q -t "${IMAGE_NAME}" "${SCRIPT_DIR}" > /dev/null

# 2. Ensure named volume exists
if ! docker volume inspect "${VOLUME_NAME}" > /dev/null 2>&1; then
    echo "Creating named volume: ${VOLUME_NAME}"
    docker volume create "${VOLUME_NAME}" > /dev/null
fi

# Helper to run a container with the volume and script mounted
run_in_container()
                   {
    local exp_num="$1"
    local script_path="${SCRIPT_DIR}/exp${exp_num}/run.sh"
    local container_name="spike-exp-${exp_num}-$$"

    echo ">>> Running Experiment ${exp_num} in Docker container..."
    docker run --rm \
        --name "${container_name}" \
        -v "${VOLUME_NAME}:/origin" \
        -v "${script_path}:/run-exp.sh:ro" \
        -u vscode \
        "${IMAGE_NAME}" \
        bash /run-exp.sh
}

# Prepare bundle on volume for experiment 5
prepare_bundle()
                 {
    echo "Preparing git bundle from committed tree..."
    local tmp_bundle="/tmp/dots-spike-bundle-$$.bundle"
    git -C "${DOTS_ROOT}" bundle create "${tmp_bundle}" HEAD > /dev/null
    docker run --rm \
        -v "${VOLUME_NAME}:/origin" \
        -v "${tmp_bundle}:/tmp/bundle:ro" \
        -u vscode \
        "${IMAGE_NAME}" \
        cp /tmp/bundle /origin/dots.bundle
    rm -f "${tmp_bundle}"
}

case "${EXPERIMENT}" in
    1)
        run_in_container 1
        ;;
    2)
        run_in_container 2
        ;;
    3)
        run_in_container 3
        ;;
    4)
        run_in_container 4
        ;;
    5)
        prepare_bundle
        run_in_container 5
        ;;
    6)
        run_in_container 6
        ;;
    7)
        run_in_container 7
        ;;
    all)
        echo "Resetting ${VOLUME_NAME} volume for clean run..."
        docker volume rm -f "${VOLUME_NAME}" > /dev/null 2>&1 || true
        docker volume create "${VOLUME_NAME}" > /dev/null
        echo "Running all experiments 1 through 7 in sequence..."
        prepare_bundle
        run_in_container 1
        run_in_container 2
        run_in_container 3
        run_in_container 4
        run_in_container 5
        run_in_container 6
        run_in_container 7
        echo "=== All spike experiments completed successfully ==="
        ;;
    clean)
        echo "Removing named volume: ${VOLUME_NAME}"
        docker volume rm "${VOLUME_NAME}" || true
        ;;
    *)
        echo "Usage: $0 [1|2|3|4|5|6|7|all|clean]" >&2
        exit 1
        ;;
esac
