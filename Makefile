# Build/publish helper for the bootc-fedora image.
# Override on the command line, e.g.:
#   make build FEDORA_VERSION=43
#   make push ORG=my-org

FEDORA_VERSION ?= 44
IMAGE          ?= localhost/bootc-fedora
TAG            ?= latest
ORG            ?=
REMOTE_TAG     ?= ghcr.io/$(ORG)/bootc-fedora:$(FEDORA_VERSION)

.PHONY: build lint push

# Build the image. `bootc container lint` runs at the end of the Containerfile,
# so a successful build already means the image is validated.
build:
	podman build --build-arg FEDORA_VERSION=$(FEDORA_VERSION) -t $(IMAGE):$(TAG) .

# Explicit re-lint (handy after editing the Containerfile without a full rebuild).
lint:
	podman run --rm $(IMAGE):$(TAG) bootc container lint

# Tag and push to ghcr.io. Requires `podman login ghcr.io` once.
push:
	@test -n "$(ORG)" || { echo "usage: make push ORG=<your-org>"; exit 1; }
	podman tag $(IMAGE):$(TAG) $(REMOTE_TAG)
	podman push $(REMOTE_TAG)
	@echo "OK: $(REMOTE_TAG)"
