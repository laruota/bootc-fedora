#!/usr/bin/env bash
# Bootstrap flatpaks system-wide on the target machine (first-run setup).
# Run as a normal user (sudo is used internally). Flatpaks land in
# /var/lib/flatpak (machine state) and update independently of the OS.
# Edit the FLATPAKS list below to match the apps you want.
set -euox pipefail

# Add full Flathub (includes proprietary apps like Chrome; the GNOME Software
# "third-party" toggle only enables the Fedora-filtered subset).
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# >>> EDIT THIS LIST <<<
FLATPAKS=(
    com.google.Chrome
    md.obsidian.Obsidian
    org.gimp.GIMP
    org.libreoffice.LibreOffice
    com.spotify.Client
    org.gnome.meld
    org.inkscape.Inkscape
    com.github.johnfactotum.Foliate
)

if [ "${#FLATPAKS[@]}" -eq 0 ]; then
    echo "Lista FLATPAKS vuota: modifica lo script."
    exit 1
fi

sudo flatpak install --system -y flathub "${FLATPAKS[@]}"