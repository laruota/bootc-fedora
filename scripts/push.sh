#!/usr/bin/env bash
# Pubblica l'immagine bootc su ghcr.io (public, gratis, pull anonimo).
# Prerequisito: podman login ghcr.io (una volta).
# Uso: ./scripts/push.sh <org> [tag] [source-image] [source-tag]
#
# Prima del push esegue scripts/rechunk.sh: l'immagine pubblicata usa layer
# content-based, così `bootc upgrade` scarica solo i layer cambiati.
# SKIP_RECHUNK=1 per pubblicare l'immagine così com'è.
# PREVIOUS_BUILD=docker://... (opzionale) ancora il piano dei layer alla build
# precedente; utile dopo la prima pubblicazione chunked.
#
# Il tag di default (versione Fedora) è letto dal Containerfile via base-ref.sh,
# così non può divergere dalla base buildata.
# Pubblica gli stessi tag della CI:
#   :<tag>            canale mutabile (quello che segue `bootc upgrade`)
#   :latest
#   :<tag>-<YYYYMMDD> riferimento per data (riscritto a ogni build del giorno)
#   :<tag>-<sha7>     riferimento per commit (riscritto dal rebuild giornaliero)
# Solo il digest identifica una build in modo stabile.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ORG="${1:?Uso: ./scripts/push.sh <org> [tag] [source-image] [source-tag]}"
TAG="${2:-$("$here/base-ref.sh" version)}"
SOURCE_IMAGE="${3:-localhost/bootc-fedora}"
SOURCE_TAG="${4:-latest}"
SOURCE="${SOURCE_IMAGE}:${SOURCE_TAG}"

DATE="${DATE:-$(date -u +%Y%m%d)}"
SHA="${SHA:-$(git -C "$here/.." rev-parse --short=7 HEAD 2>/dev/null || echo local)}"
REPO="ghcr.io/${ORG}/bootc-fedora"

# Rechunk in place (source and target tag are the same). PREVIOUS_BUILD is
# passed through to rechunk.sh when set by the caller.
if [ "${SKIP_RECHUNK:-0}" != "1" ]; then
    "$here/rechunk.sh" "$SOURCE_IMAGE" "$SOURCE_TAG"
fi

podman tag "$SOURCE" "$REPO:${TAG}"
podman tag "$SOURCE" "$REPO:latest"
podman tag "$SOURCE" "$REPO:${TAG}-${DATE}"
podman tag "$SOURCE" "$REPO:${TAG}-${SHA}"

digestfile=$(mktemp)
trap 'rm -f "$digestfile"' EXIT

# Prima i riferimenti per data/sha, poi i canali: se un push fallisce a metà,
# `:tag` e `:latest` restano sulla build precedente (quella buona).
podman push --digestfile "$digestfile" "$REPO:${TAG}-${DATE}"
digest=$(cat "$digestfile")
podman push "$REPO:${TAG}-${SHA}"
podman push "$REPO:${TAG}"
podman push "$REPO:latest"

echo "OK: $REPO:$TAG, :latest, :$TAG-$DATE, :$TAG-$SHA"
echo "digest: $digest"
echo "pin sulla target: sudo bootc switch $REPO@$digest"
