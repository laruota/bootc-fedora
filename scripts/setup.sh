#!/usr/bin/env bash
# Install/remove packages for the custom bootc image.
# Runs inside the container build. Extend the lists below to customize.
set -euox pipefail

# --- Install packages -------------------------------------------------------
# install_weak_deps=False: evita che Recommends trascinino pacchetti che
# rimuoveremmo subito dopo (gcc, nodejs22, xsel, evince-djvu, snapper, ...).
# I pochi utili vengono aggiunti esplicitamente sotto.
dnf5 install -y --setopt=install_weak_deps=False \
    android-tools \
    bat \
    btrfs-assistant \
    cheat \
    cheat-community-cheatsheets \
    dconf-editor \
    fd-find \
    fzf \
    gh \
    git-delta \
    git-gui \
    gnome-tweaks \
    GraphicsMagick \
    gstreamer1-plugin-openh264 \
    mat2 \
    neovim \
    nmap \
    nnn \
    pipx \
    podman-compose \
    python3-pip \
    qpdf \
    ripgrep \
    seahorse \
    shellcheck \
    solaar \
    solaar-udev \
    stow \
    sushi \
    syncthing \
    tldr \
    tmux \
    trash-cli \
    tree \
    wl-clipboard \
    zenity \
    zoxide \
    zsh

# --- Remove packages --------------------------------------------------------
# Replace vim with neovim (vim may not be installed on Silverblue at all)
dnf5 remove -y vim-minimal vim-enhanced || true

# Unneeded packages (remove only the ones actually present):
#   - GNOME apps / input engines / NM plugins / Exchange support
#   - malcontent-control: standalone parental-controls GUI
#     (the "malcontent" core stays: hard dep of gnome-control-center,
#      removing it cascades into gnome-shell and the whole desktop)
#   - nodejs22 (+ npm): nothing requires it, saved ~169 MiB
#   - xsel: orfano (xclip rimosso anche lui, nessuno dei due serve)
#   - gcc/glibc-devel/kernel-headers/libxcrypt-devel: compile toolchain,
#     unused on an immutable system (use toolbox/distrobox to compile)
REMOVE="gnome-tour \
    ibus-anthy ibus-hangul ibus-m17n ibus-typing-booster ibus-libpinyin \
    NetworkManager-adsl evolution-ews evolution-ews-core evolution-ews-langpacks \
    gnome-shell-extension-background-logo \
    malcontent-control \
    nodejs22 \
    xsel \
    gcc glibc-devel kernel-headers libxcrypt-devel"
# NOTE: perl stays — stow (dotfiles) is a Perl program and needs it.
INSTALLED=""
for p in $REMOVE; do
    if [ -n "$(dnf5 repoquery --installed "$p" 2>/dev/null)" ]; then
        INSTALLED="$INSTALLED $p"
    fi
done
if [ -n "$INSTALLED" ]; then
    # shellcheck disable=SC2086
    dnf5 remove -y $INSTALLED
fi

# Point editor/vi alternatives to neovim when provided
update-alternatives --set editor /usr/bin/nvim 2>/dev/null || true
update-alternatives --set vi /usr/bin/nvim 2>/dev/null || true

# Provide a vi alias for nvim (vim was removed and nvim does not ship a vi link)
if [ -e /usr/bin/nvim ] && [ ! -e /usr/bin/vi ]; then
    ln -s /usr/bin/nvim /usr/bin/vi
fi

# --- Make zsh the default shell for NEW users -------------------------------
# /etc/default/useradd is read by useradd; SHELL here applies to every user
# created on the target machine (first boot / manual useradd).
sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd
grep -q '^SHELL=/bin/zsh' /etc/default/useradd || echo 'SHELL=/bin/zsh' >> /etc/default/useradd

# --- Enable sshd (TCP:22) -----------------------------------------------------
# The Silverblue base leaves sshd.service disabled (only the systemd-ssh-generator
# vsock/unix listeners are active). bcvk connects to its VMs over TCP port 22,
# so enabling sshd makes the image testable with bcvk (and SSH-able on the
# target machine). Host keys are generated automatically at first boot.
systemctl enable sshd.service

# --- Remove third-party repo files we don't want ------------------------------
# These come from fedora-workstation-repositories. They are disabled by default,
# but on the immutable deployed system /etc is read-only, so they would never be
# (re)enabled anyway. Removing them leaves no trace on the target.
# Kept: fedora, fedora-updates, fedora-cisco-openh264, vscode.
rm -f /etc/yum.repos.d/rpmfusion-nonfree-*.repo \
    /etc/yum.repos.d/_copr:*PyCharm.repo \
    /etc/yum.repos.d/google-chrome.repo