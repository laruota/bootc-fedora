# Custom GNOME bootc image derived from Fedora Silverblue.
# Bump Fedora: change FEDORA_VERSION below (single source of truth).
# Build: podman build --build-arg FEDORA_VERSION=44 -t localhost/bootc-fedora:latest .
# Base: official GNOME atomic bootc image (dnf5 + bootc included).

ARG FEDORA_VERSION=44
FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION}

# Build metadata (VERSION/SOURCE_COMMIT are passed by CI or the Makefile).
ARG VERSION=dev
ARG SOURCE_COMMIT=""

LABEL org.opencontainers.image.title="bootc-fedora" \
      org.opencontainers.image.description="Custom GNOME bootc image based on Fedora Silverblue" \
      org.opencontainers.image.source="https://github.com/laruota/bootc-fedora" \
      org.opencontainers.image.vendor="laruota" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}" \
      org.opencontainers.image.licenses="GPL-3.0-only"

# NOTE: the build steps below are kept as separate RUN layers on purpose, so a
# change to one script (e.g. only fonts.sh) only invalidates that layer during
# development. Each layer mounts the dnf5 caches to avoid re-downloading metadata
# and a tmpfs for /var/log to keep the image free of build-time log churn.
# The scripts are BIND-MOUNTED into each RUN (--mount=type=bind), not copied:
# no build-context leftovers end up in the image layer history.

# Install / remove packages (see scripts/setup.sh)
RUN --mount=type=bind,source=scripts,target=/tmp/scripts \
    --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/setup.sh

# Install Visual Studio Code (see scripts/vscode.sh)
RUN --mount=type=bind,source=scripts,target=/tmp/scripts \
    --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/vscode.sh

# Trim unneeded international fonts (see scripts/fonts.sh)
RUN --mount=type=bind,source=scripts,target=/tmp/scripts \
    --mount=type=cache,destination=/var/cache/libdnf5 \
    --mount=type=cache,destination=/var/lib/dnf5 \
    --mount=type=tmpfs,destination=/var/log \
    bash /tmp/scripts/fonts.sh

# Keep the flatpak bootstrap script available on the target machine
# (run it there with sudo; it does NOT run during the image build)
COPY --chmod=0755 scripts/bootstrap-flatpaks.sh /usr/local/bin/bootstrap-flatpaks.sh

# Same for the Python bootstrap (run it on the target as the user)
COPY --chmod=0755 scripts/bootstrap-python.sh /usr/local/bin/bootstrap-python.sh

# Host locale/timezone and default editor. NOTE: OCI ENV vars do NOT reach
# sessions of a bootc-deployed host (they are container-runtime metadata):
# anything that must affect the installed OS has to be written to the fs.
RUN ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    printf 'LANG=it_IT.UTF-8\n' > /etc/locale.conf && \
    printf '#!/bin/sh\nexport EDITOR=nvim VISUAL=nvim\n' > /etc/profile.d/50-editor.sh && \
    chmod 0644 /etc/profile.d/50-editor.sh

# Default root filesystem type for bootc install / image-builder.
# Fedora (Silverblue base) ships no default, so set btrfs explicitly:
# this avoids needing `--rootfs btrfs` on bootc-image-builder and
# `--filesystem btrfs` on `bootc install to-disk`.
RUN mkdir -p /usr/lib/bootc/install && \
    printf '[install.filesystem.root]\ntype = "btrfs"\n' \
    > /usr/lib/bootc/install/50-bootc-fedora.toml

# Validate the image
RUN bootc container lint
