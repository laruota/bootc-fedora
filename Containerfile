# Custom GNOME bootc image derived from Fedora Silverblue.
# Bump Fedora: change FEDORA_VERSION below (single source of truth).
# Build: podman build --build-arg FEDORA_VERSION=44 -t localhost/bootc-fedora:latest .
# Base: official GNOME atomic bootc image (dnf5 + bootc included).

ARG FEDORA_VERSION=44
FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION}

COPY --chmod=0755 scripts/ /tmp/scripts/

# NOTE: the build steps below are kept as separate RUN layers on purpose, so a
# change to one script (e.g. only fonts.sh) only invalidates that layer during
# development. Each layer mounts the dnf5 caches to avoid re-downloading metadata
# and a tmpfs for /var/log to keep the image free of build-time log churn.

# Install / remove packages (see scripts/setup.sh)
RUN --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/setup.sh

# Install Visual Studio Code (see scripts/vscode.sh)
RUN --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/vscode.sh

# Trim unneeded international fonts (see scripts/fonts.sh)
RUN --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/fonts.sh

# Keep the flatpak bootstrap script available on the target machine
# (run it there with sudo; it does NOT run during the image build)
COPY --chmod=0755 scripts/bootstrap-flatpaks.sh /usr/local/bin/bootstrap-flatpaks.sh

# Same for the Python bootstrap (run it on the target as the user)
COPY --chmod=0755 scripts/bootstrap-python.sh /usr/local/bin/bootstrap-python.sh

RUN rm -rf /tmp/scripts

# Default root filesystem type for bootc install / image-builder.
# Fedora (Silverblue base) ships no default, so set btrfs explicitly:
# this avoids needing `--rootfs btrfs` on bootc-image-builder and
# `--filesystem btrfs` on `bootc install to-disk`.
RUN mkdir -p /usr/lib/bootc/install && \
    printf '[install.filesystem.root]\ntype = "btrfs"\n' \
    > /usr/lib/bootc/install/50-bootc-fedora.toml

# Validate the image
RUN bootc container lint