# Custom GNOME bootc image derived from Fedora Silverblue.
# Build: podman build -t localhost/bootc-fedora:latest .
# Base: official GNOME atomic bootc image (dnf5 + bootc included).

FROM quay.io/fedora/fedora-silverblue:44

COPY --chmod=0755 scripts/ /tmp/scripts/

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

RUN rm -rf /tmp/scripts

# Validate the image
RUN bootc container lint