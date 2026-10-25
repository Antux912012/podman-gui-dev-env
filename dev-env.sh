#!/usr/bin/env bash
set -e

DISTRO=${1:-debian} # "debian" or "fedora"
ACTION=${2:-shell}  # "build", "shell", "test-gui", "verify", or "run"
IMAGE_NAME="localhost/dev-${DISTRO}:latest"
CONTAINER_NAME="dev-${DISTRO}-instance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$ACTION" == "build" ]; then
    podman build \
        --build-arg USER_UID=$(id -u) \
        --build-arg USER_GID=$(id -g) \
        -t "$IMAGE_NAME" \
        -f "${SCRIPT_DIR}/Containerfile.${DISTRO}" "${SCRIPT_DIR}"
    exit 0
fi

# Ensure X11 access for local rootless containers
if command -v xhost >/dev/null 2>&1; then
    xhost +local: >/dev/null 2>&1 || true
fi

mkdir -p "${SCRIPT_DIR}/.flatpak-data"

PODMAN_GUI_FLAGS=(
    --rm
    --replace
    --name "$CONTAINER_NAME"
    --hostname "dev-${DISTRO}"
    --userns=keep-id
    --group-add keep-groups
    --pid=host
    --ipc=host
    --net=host
    --security-opt label=disable
    --security-opt seccomp=unconfined
    --security-opt apparmor=unconfined
    --security-opt unmask=ALL
    --device /dev/dri
    --device /dev/fuse
    -e DISPLAY="$DISPLAY"
    -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY"
    -e XDG_RUNTIME_DIR="/run/user/$(id -u)"
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro
    -v "${SCRIPT_DIR}:/workspace:Z"
    -v "${SCRIPT_DIR}/.flatpak-data:/home/devuser/.local/share/flatpak:Z"
)

if [ -t 0 ]; then
    PODMAN_GUI_FLAGS+=(-it)
else
    PODMAN_GUI_FLAGS+=(-i)
fi

# Mount user runtime directory (Wayland, D-Bus session bus, Flatpak instance tracking, PipeWire)
if [ -d "/run/user/$(id -u)" ]; then
    PODMAN_GUI_FLAGS+=(
        -e DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
        -v "/run/user/$(id -u):/run/user/$(id -u)"
    )
fi

# Mount EFI variables read-only if present on host (for UEFI Secure Boot detection)
if [ -d "/sys/firmware/efi/efivars" ]; then
    PODMAN_GUI_FLAGS+=(
        -v "/sys/firmware/efi/efivars:/sys/firmware/efi/efivars:ro"
        -v "/sys/firmware/efi/efivars:/run/host/sys/firmware/efi/efivars:ro"
    )
fi

# Mount host system Flatpak runtimes read-only if present
if [ -d "/var/lib/flatpak" ]; then
    PODMAN_GUI_FLAGS+=(-v "/var/lib/flatpak:/var/lib/flatpak:ro")
fi

# Mount system D-Bus socket if active on host
if [ -S "/run/dbus/system_bus_socket" ]; then
    PODMAN_GUI_FLAGS+=(-v "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket")
fi

if [ "$ACTION" == "test-gui" ]; then
    echo "Testing GUI rendering on ${DISTRO}..."
    podman run "${PODMAN_GUI_FLAGS[@]}" "$IMAGE_NAME" bash -c "glxgears -info || xeyes"
elif [ "$ACTION" == "verify" ]; then
    echo "Verifying ${DISTRO} container environment, Wayland, X11, GPU, Flatpak, Vala, GTK4, and Rust..."
    podman run "${PODMAN_GUI_FLAGS[@]}" "$IMAGE_NAME" bash -c "id && flatpak --version && flatpak-builder --version && valac --version && pkg-config --modversion gtk4 libadwaita-1 && rustc --version && cargo --version && meson --version && wayland-info | head -n 5 && glxinfo -B | head -n 10"
elif [ "$ACTION" == "run" ]; then
    shift 2
    podman run "${PODMAN_GUI_FLAGS[@]}" "$IMAGE_NAME" "$@"
else
    podman run "${PODMAN_GUI_FLAGS[@]}" "$IMAGE_NAME" /bin/bash
fi
