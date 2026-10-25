# Podman & Docker GUI Development Environments (Debian & Fedora)

Rootless **Podman** and **Docker Compose** development containers with full **Wayland**, **X11 (XWayland)**, **Direct Rendering (DRI/Mesa OpenGL)**, and **FUSE** passthrough.

Pre-configured with toolchains for:
- **C / C++:** GCC, Clang, GDB, Valgrind, Meson, Ninja, pkg-config, gettext
- **Vala:** `valac`, `valadoc`, `libgee`, `json-glib`, `libsoup3`, GObject Introspection
- **GTK4 & Libadwaita:** `gtk4` (`libgtk-4-dev` / `gtk4-devel`), `libadwaita-1`, `gtk4-builder-tool`, `gtk4-demo`
- **Rust:** `rustc`, `cargo`, `rustfmt`, `clippy`, `rust-src`, `libclang`
- **Flatpak Packaging:** `flatpak`, `flatpak-builder`, `ostree`, `elfutils`, `appstream`, `desktop-file-utils`, `fuse3`, and pre-configured **Flathub** remote

---

## Included Files

- `Containerfile.debian` — Based on `debian:bookworm`
- `Containerfile.fedora` — Based on `fedora:latest`
- `compose.yaml` — Universal Compose file for `podman compose` and `docker compose`
- `dev-env.sh` — CLI helper script for building, launching interactive shells, and testing GUI/Wayland/OpenGL forwarding

---

## Quick Start with Podman Compose / Docker Compose

Allow local X11 connections on the host (if using X11/XWayland):
```bash
xhost +local:
```

### Build Images
```bash
# Using Podman Compose
USER_UID=$(id -u) USER_GID=$(id -g) podman compose build

# Or using Docker Compose
USER_UID=$(id -u) USER_GID=$(id -g) docker compose build
```

### Run an Interactive Development Shell
```bash
# Launch Debian development container
podman compose run --rm dev-debian

# Launch Fedora development container
podman compose run --rm dev-fedora
```

---

## Quick Start with `dev-env.sh`

```bash
# Build both environments
./dev-env.sh debian build
./dev-env.sh fedora build

# Verify Wayland, X11, OpenGL, Flatpak, Vala, GTK4, and Rust toolchains
./dev-env.sh debian verify
./dev-env.sh fedora verify

# Open an interactive shell
./dev-env.sh debian shell
./dev-env.sh fedora shell

# Test GUI rendering (glxgears / xeyes)
./dev-env.sh debian test-gui
./dev-env.sh fedora test-gui
```
