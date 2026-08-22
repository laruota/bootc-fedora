#!/usr/bin/env bash
# Bootstrap flatpaks system-wide on the target machine (first-run setup).
# Run as a normal user (sudo is used internally). Flatpaks land in
# /var/lib/flatpak (machine state) and update independently of the OS.
# Edit the FLATPAKS list below to match the apps you want.
#
# NOTE: everything installs from the FULL Flathub remote (proprietary apps and
# codecs included — apps bundle their own codecs in the sandbox). The Fedora
# flatpak remote is NOT used (it stays configured but inert; remove with
# `flatpak remote-delete --system fedora` if you don't want it).
set -euo pipefail

# Add full Flathub (includes proprietary apps like Chrome; the GNOME Software
# "third-party" toggle only enables the Fedora-filtered subset).
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# >>> EDIT THIS LIST <<<
FLATPAKS=(
    com.belmoussaoui.Decoder
    com.github.finefindus.eyedropper
    com.github.huluti.Curtail
    com.github.jeromerobert.pdfarranger
    com.github.johnfactotum.Foliate
    com.github.tchx84.Flatseal
    com.github.xournalpp.xournalpp
    com.google.Chrome
    com.mattjakeman.ExtensionManager
    com.transmissionbt.Transmission
    de.haeckerfelix.Shortwave
    de.wwwtech.gitte
    io.github.alescdb.mailviewer
    io.github.celluloid_player.Celluloid
    io.github.flattool.Warehouse
    it.mijorus.gearlever
    md.obsidian.Obsidian
    net.nokyan.Resources
    org.fedoraproject.MediaWriter
    org.gimp.GIMP
    org.gnome.Calculator
    org.gnome.Calendar
    org.gnome.Characters
    org.gnome.Decibels
    org.gnome.FileRoller
    org.gnome.FontViewer
    org.gnome.Logs
    org.gnome.Loupe
    org.gnome.Maps
    org.gnome.Papers
    org.gnome.Snapshot
    org.gnome.Solanum
    org.gnome.TextEditor
    org.gnome.baobab
    org.gnome.gitlab.somas.Apostrophe
    org.gnome.gthumb
    org.gnome.meld
    org.inkscape.Inkscape
    org.libreoffice.LibreOffice
    org.remmina.Remmina
    org.virt_manager.virt-viewer
)

if [ "${#FLATPAKS[@]}" -eq 0 ]; then
    echo "Lista FLATPAKS vuota: modifica lo script."
    exit 1
fi

sudo flatpak install --system -y flathub "${FLATPAKS[@]}"