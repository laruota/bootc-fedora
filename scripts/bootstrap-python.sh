#!/usr/bin/env bash
# Bootstrap Python libraries/tools on the target machine (first-run setup).
# Run as a normal user. Installs to ~/.local (user site-packages / pipx),
# so everything survives on the immutable system.
# Edit the lists below to match the packages you want.
set -euox pipefail

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

# PEP 668: Fedora blocks direct pip installs -> --break-system-packages
# for user-site installs (the "user" equivalent of the playbook's flag)
pip install --user --break-system-packages "${PIP_PACKAGES[@]}"