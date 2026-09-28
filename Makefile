# Build/publish helper for the bootc-fedora image.
# Override on the command line, e.g.:
#   make build FEDORA_VERSION=44
#   make push ORG=my-org

# Single source of truth for the Fedora version: ARG FEDORA_VERSION in the
# Containerfile (override with `make build FEDORA_VERSION=X` for one-offs).
FEDORA_VERSION ?= $(shell sed -n 's/^ARG FEDORA_VERSION=//p' Containerfile)
IMAGE          ?= localhost/bootc-fedora
INSTALLER_IMAGE ?= localhost/bootc-fedora-installer
TAG            ?= latest
ORG            ?=
SHELLCHECK_IMAGE ?= docker.io/koalaman/shellcheck-alpine:v0.11.0

.PHONY: build lint shellcheck smoke push installer iso

# Build the image. `bootc container lint` runs at the end of the Containerfile,
# so a successful build already means the image is validated.
build:
	podman build --build-arg FEDORA_VERSION=$(FEDORA_VERSION) \
	    --build-arg "SOURCE_COMMIT=$$(git rev-parse HEAD 2>/dev/null)" \
	    -t $(IMAGE):$(TAG) .

# Explicit re-lint (handy after editing the Containerfile without a full rebuild).
lint:
	podman run --rm $(IMAGE):$(TAG) bootc container lint

# Lint scripts without adding ShellCheck to the deployed operating system.
shellcheck:
	podman run --rm -v "$(CURDIR):/src:ro,Z" -w /src $(SHELLCHECK_IMAGE) shellcheck -s bash scripts/*.sh

# Check the custom operating-system content without requiring a VM boot.
smoke:
	podman run --rm $(IMAGE):$(TAG) bash -ceu 'bootc container lint; test -x /usr/libexec/bootc-fedora/bootstrap-flatpaks.sh; test -x /usr/libexec/bootc-fedora/bootstrap-python.sh; test -f /usr/lib/bootc/install/50-bootc-fedora.toml; grep -Fxq "type = \"btrfs\"" /usr/lib/bootc/install/50-bootc-fedora.toml; readlink /etc/localtime | grep -Fxq /usr/share/zoneinfo/Europe/Rome; grep -Fxq LANG=it_IT.UTF-8 /etc/locale.conf; command -v code; rpm -q google-noto-sans-vf-fonts google-noto-serif-vf-fonts google-noto-sans-mono-vf-fonts google-noto-color-emoji-fonts; if systemctl is-enabled sshd >/dev/null 2>&1; then exit 1; fi'

# Tag and push to ghcr.io via scripts/push.sh. Requires `podman login ghcr.io` once.
push:
	@test -n "$(ORG)" || { echo "usage: make push ORG=<your-org>"; exit 1; }
	./scripts/push.sh $(ORG) $(FEDORA_VERSION) $(IMAGE) $(TAG)

# Build the installer container (OS + Anaconda + ISO tools) used by image-builder.
installer:
	sudo podman build --build-arg BOOTC_IMAGE=$(IMAGE):$(TAG) \
	    -t $(INSTALLER_IMAGE):$(TAG) iso/

# Build the installer ISO with osbuild image-builder (bootc-generic-iso: no dnf
# depsolve, so no repository handling needed). Requires on the host:
#   sudo dnf install image-builder osbuild osbuild-depsolve-dnf
iso: installer
	sudo image-builder build \
	    --bootc-ref $(INSTALLER_IMAGE):$(TAG) \
	    --bootc-default-fs btrfs \
	    bootc-generic-iso
