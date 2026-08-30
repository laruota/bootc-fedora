#!/usr/bin/env bash
# Pubblica l'immagine bootc su ghcr.io (public, gratis, pull anonimo).
# Prerequisito: podman login ghcr.io (una volta).
# Uso: ./scripts/push.sh <org> [tag] [source-image] [source-tag]
set -euo pipefail

ORG="${1:?Uso: ./scripts/push.sh <org> [tag] [source-image] [source-tag]}"
TAG="${2:-44}"
SOURCE_IMAGE="${3:-localhost/bootc-fedora}"
SOURCE_TAG="${4:-latest}"
SOURCE="${SOURCE_IMAGE}:${SOURCE_TAG}"
VERSIONED_TARGET="ghcr.io/${ORG}/bootc-fedora:${TAG}"
LATEST_TARGET="ghcr.io/${ORG}/bootc-fedora:latest"

podman tag "$SOURCE" "$VERSIONED_TARGET"
podman tag "$SOURCE" "$LATEST_TARGET"
podman push "$VERSIONED_TARGET"
podman push "$LATEST_TARGET"
echo "OK: $VERSIONED_TARGET e $LATEST_TARGET"
