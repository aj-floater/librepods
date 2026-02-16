#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run this script as your normal user, not with sudo."
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PREFIX="${HOME}/.local"
PLASMOID_SRC="${REPO_DIR}/plasmoid/org.kde.plasma.librepods"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/org.kde.plasma.librepods"
RESTART_PLASMA=1
SKIP_BUILD=0

usage() {
    cat <<'EOF'
Usage: linux/dev-update-plasmoid.sh [options]

Options:
  --no-restart   Do not restart plasmashell after install
  --skip-build   Skip cmake build step
  -h, --help     Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-restart)
            RESTART_PLASMA=0
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "kpackagetool6 not found in PATH."
    exit 1
fi

if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
    cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}"
fi

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
    cmake --build "${BUILD_DIR}" -j"$(nproc)"
fi

cmake --install "${BUILD_DIR}" --prefix "${PREFIX}"

rm -rf "${PLASMOID_DST}"
kpackagetool6 --type Plasma/Applet --install "${PLASMOID_SRC}"

if [[ "${RESTART_PLASMA}" -eq 1 ]]; then
    kquitapp6 plasmashell || true
    nohup plasmashell --replace >/tmp/librepods-plasmashell.log 2>&1 & disown
fi

echo "LibrePods plasmoid updated."
