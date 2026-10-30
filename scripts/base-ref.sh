#!/usr/bin/env bash
# Legge la base dal Containerfile. Unica implementazione del parsing della riga
# FROM, usata da Makefile, workflow e scripts/push.sh.
#
# La riga FROM usa il tag mobile della release:
#   FROM quay.io/fedora/fedora-silverblue:45
# È accettata anche la forma pinnata a mano (tag@sha256:…): il digest viene
# ignorato nella lettura, così lo script continua a funzionare.
#
# Uso: scripts/base-ref.sh {ref|version}
#   ref      quay.io/fedora/fedora-silverblue:45
#   version  45
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
containerfile="${CONTAINERFILE:-$root/Containerfile}"

raw=$(sed -n 's|^FROM \([^[:space:]]*\).*|\1|p' "$containerfile")
ref=${raw%%@*}
version=${ref##*:}

die() {
    echo "$*" >&2
    exit 1
}

case "${1:-}" in
    ref)
        case "$ref" in
            */fedora-silverblue:*) echo "$ref" ;;
            *) die "Containerfile: riga FROM della base non trovata (atteso <registry>/fedora-silverblue:<versione>)" ;;
        esac
        ;;
    version)
        case "$ref" in
            */fedora-silverblue:[0-9]*) echo "$version" ;;
            *) die "Containerfile: versione Fedora non ricavabile dalla riga FROM" ;;
        esac
        ;;
    *)
        die "uso: $0 {ref|version}"
        ;;
esac
