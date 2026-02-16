#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PLASMOID_SRC="${REPO_DIR}/plasmoid/org.kde.plasma.librepods"

RESTART_PLASMA=1
SKIP_BUILD=0
ORIGINAL_ARGS=("$@")

usage() {
    cat <<'USAGE'
Usage: linux/dev-update-plasmoid.sh [options]

Options:
  --no-restart   Do not restart plasmashell after install
  --skip-build   Skip cmake build step
  -h, --help     Show this help
USAGE
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

if [[ "${EUID}" -eq 0 ]]; then
    if [[ -z "${SUDO_USER:-}" || "${SUDO_USER}" == "root" ]]; then
        echo "Run as your normal user, or run via sudo from your user account."
        exit 1
    fi
    TARGET_USER="${SUDO_USER}"
    TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
else
    TARGET_USER="${USER}"
    TARGET_HOME="${HOME}"
fi

if [[ -z "${TARGET_HOME}" ]]; then
    echo "Could not resolve home directory for user ${TARGET_USER}."
    exit 1
fi

PREFIX="${TARGET_HOME}/.local"
PLASMOID_DST="${PREFIX}/share/plasma/plasmoids/org.kde.plasma.librepods"

INSTALL_TARGETS=(
    "${PREFIX}/bin/librepods"
    "${PREFIX}/share/applications/me.kavishdevar.librepods.desktop"
    "${PREFIX}/share/icons/hicolor/512x512/apps/librepods.png"
    "${PREFIX}/share/dbus-1/services/me.kavishdevar.librepods.service"
    "${PREFIX}/share/librepods"
    "${PLASMOID_DST}"
)

needs_chown=0
for target in "${INSTALL_TARGETS[@]}"; do
    if [[ -e "${target}" ]]; then
        owner="$(stat -c '%U' "${target}" 2>/dev/null || true)"
        if [[ -n "${owner}" && "${owner}" != "${TARGET_USER}" ]]; then
            needs_chown=1
            break
        fi
    fi
done

if [[ "${needs_chown}" -eq 1 ]]; then
    if [[ "${EUID}" -eq 0 ]]; then
        chown -R "${TARGET_USER}:${TARGET_USER}" "${INSTALL_TARGETS[@]}" 2>/dev/null || true
    else
        echo "Install targets in ${PREFIX} are not owned by ${TARGET_USER}."
        echo "Fix once with:"
        echo "  sudo chown -R \"${TARGET_USER}:${TARGET_USER}\" \\" 
        for target in "${INSTALL_TARGETS[@]}"; do
            echo "    \"${target}\" \\" 
        done
        echo "    2>/dev/null || true"
        exit 1
    fi
fi

if [[ "${EUID}" -eq 0 && "${LIBREPODS_DEV_UPDATE_AS_USER:-0}" != "1" ]]; then
    TARGET_UID="$(id -u "${TARGET_USER}")"
    DBUS_ADDR="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${TARGET_UID}/bus}"
    XDG_DIR="${XDG_RUNTIME_DIR:-/run/user/${TARGET_UID}}"

    exec sudo -u "${TARGET_USER}" env \
        HOME="${TARGET_HOME}" \
        USER="${TARGET_USER}" \
        LOGNAME="${TARGET_USER}" \
        XDG_RUNTIME_DIR="${XDG_DIR}" \
        DBUS_SESSION_BUS_ADDRESS="${DBUS_ADDR}" \
        LIBREPODS_DEV_UPDATE_AS_USER=1 \
        PATH="${PATH}" \
        "${BASH_SOURCE[0]}" "${ORIGINAL_ARGS[@]}"
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
