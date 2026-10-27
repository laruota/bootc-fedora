#!/usr/bin/env bash
# Unica implementazione della lettura della base pinnata nel Containerfile.
# Usata da Makefile, .github/workflows/build.yml e bump-base.yml, così il
# formato della riga FROM è definito in un posto solo.
#
# Uso: scripts/base-ref.sh {ref|version|digest|full|upstream|check}
#   ref      quay.io/fedora/fedora-silverblue:45
#   version  45
#   digest   sha256:…  (quello pinnato nel Containerfile)
#   full     ref@digest
#   upstream digest attuale del tag sul registry (richiede skopeo + jq)
#   check    confronta pinnato e upstream; esce 1 se diversi
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
containerfile="${CONTAINERFILE:-$root/Containerfile}"

ref=$(sed -n 's|^FROM \(quay.io/fedora/fedora-silverblue:[0-9][0-9]*\)@sha256:[0-9a-f]\{64\}.*|\1|p' "$containerfile")
digest=$(sed -n 's|^FROM quay.io/fedora/fedora-silverblue:[0-9][0-9]*@\(sha256:[0-9a-f]\{64\}\).*|\1|p' "$containerfile")

die() {
    echo "$*" >&2
    exit 1
}

case "${1:-}" in
    ref)
        [ -n "$ref" ] || die "Containerfile: riga FROM della base non pinnata per digest (tag@sha256:...)"
        echo "$ref"
        ;;
    version)
        [ -n "$ref" ] || die "Containerfile: riga FROM della base non pinnata per digest (tag@sha256:...)"
        echo "${ref##*:}"
        ;;
    digest)
        [ -n "$digest" ] || die "Containerfile: digest della base non trovato nella riga FROM"
        echo "$digest"
        ;;
    full)
        [ -n "$ref" ] && [ -n "$digest" ] || die "Containerfile: riga FROM della base non pinnata per digest (tag@sha256:...)"
        echo "$ref@$digest"
        ;;
    upstream)
        [ -n "$ref" ] || die "Containerfile: riga FROM della base non pinnata per digest (tag@sha256:...)"
        command -v skopeo >/dev/null || die "skopeo non trovato nel PATH"
        command -v jq >/dev/null || die "jq non trovato nel PATH"
        skopeo inspect --no-tags "docker://$ref" | jq -r .Digest
        ;;
    check)
        [ -n "$ref" ] && [ -n "$digest" ] || die "Containerfile: riga FROM della base non pinnata per digest (tag@sha256:...)"
        command -v skopeo >/dev/null || die "skopeo non trovato nel PATH"
        command -v jq >/dev/null || die "jq non trovato nel PATH"
        up=$(skopeo inspect --no-tags "docker://$ref" | jq -r .Digest)
        echo "pinnata:  $digest"
        echo "upstream: $up  ($ref)"
        [ "$digest" = "$up" ] || die "la base pinnata NON è aggiornata (bump-base la allinea ogni giorno)"
        ;;
    *)
        die "uso: $0 {ref|version|digest|full|upstream|check}"
        ;;
esac
