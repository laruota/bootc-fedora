#!/usr/bin/env bash
# Bootstrap Python libraries/tools on the target machine (first-run setup).
# Run as a normal user, never via sudo. Installs to ~/.local (user site-packages),
# so everything survives on the immutable system.
# Edit the lists below to match the packages you want.
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Esegui questo script come utente normale, senza sudo." >&2
    exit 1
fi

# >>> EDIT THIS LIST (libs -> pip install --user) <<<
# Solo le librerie richieste dagli script Nautilus (vedi playbook ansible).
PIP_PACKAGES=(
    pdfplumber
    pandas
    openpyxl
)

if [ "${#PIP_PACKAGES[@]}" -eq 0 ]; then
    echo "Lista PIP_PACKAGES vuota: modifica lo script."
    exit 1
fi

# PEP 668: Fedora blocks direct pip installs. These are intentionally installed
# only in the invoking user's site-packages, where Nautilus scripts can import them.
python3 -m pip install --user --break-system-packages --upgrade "${PIP_PACKAGES[@]}"
