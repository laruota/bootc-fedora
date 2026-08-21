#!/usr/bin/env bash
# Pubblica l'immagine bootc su ghcr.io (public, gratis, pull anonimo).
# Prerequisito: podman login ghcr.io (una volta).
# Uso: ./scripts/push.sh <org> [tag]     (tag default: 44)
set -euox pipefail

ORG="${1:?Uso: ./scripts/push.sh <org> [tag]}"
TAG="${2:-44}"

podman tag localhost/bootc-fedora:latest "ghcr.io/${ORG}/bootc-fedora:${TAG}"
podman push "ghcr.io/${ORG}/bootc-fedora:${TAG}"
echo "OK: ghcr.io/${ORG}/bootc-fedora:${TAG}"