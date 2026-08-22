# Build/publish helper for the bootc-fedora image.
# Override on the command line, e.g.:
#   make build FEDORA_VERSION=43
#   make push ORG=my-org

# Single source of truth for the Fedora version: ARG FEDORA_VERSION in the
# Containerfile (override with `make build FEDORA_VERSION=X` for one-offs).
FEDORA_VERSION ?= $(shell sed -n 's/^ARG FEDORA_VERSION=//p' Containerfile)
IMAGE          ?= localhost/bootc-fedora
TAG            ?= latest
ORG            ?=

.PHONY: build lint push

# Build the image. `bootc container lint` runs at the end of the Containerfile,
# so a successful build already means the image is validated.
build:
	podman build --build-arg FEDORA_VERSION=$(FEDORA_VERSION) \
	    --build-arg "SOURCE_COMMIT=$$(git rev-parse HEAD 2>/dev/null)" \
	    -t $(IMAGE):$(TAG) .

# Explicit re-lint (handy after editing the Containerfile without a full rebuild).
lint:
	podman run --rm $(IMAGE):$(TAG) bootc container lint

# Tag and push to ghcr.io via scripts/push.sh. Requires `podman login ghcr.io` once.
push:
	@test -n "$(ORG)" || { echo "usage: make push ORG=<your-org>"; exit 1; }
	./scripts/push.sh $(ORG) $(FEDORA_VERSION)
