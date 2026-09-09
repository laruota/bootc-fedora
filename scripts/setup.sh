#!/usr/bin/env bash
# Install/remove packages for the custom bootc image.
# Runs inside the container build. Extend the lists below to customize.
set -euo pipefail

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
    chezmoi \
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
    solaar \
    solaar-udev \
    sushi \
    syncthing \
    tldr \
    tmux \
    trash-cli \
    tree \
    virt-viewer \
    wl-clipboard \
    zenity \
    zoxide \
    zsh

# --- Remove packages --------------------------------------------------------
# Replace vim with neovim only when one of its packages is present.
VIM_PACKAGES=()
for p in vim-minimal vim-enhanced; do
    if dnf5 repoquery --installed --queryformat '%{name}\n' "$p" 2>/dev/null | grep -Fxq "$p"; then
        VIM_PACKAGES+=("$p")
    fi
done
if [ "${#VIM_PACKAGES[@]}" -gt 0 ]; then
    dnf5 remove -y "${VIM_PACKAGES[@]}"
fi

# Unneeded packages (remove only the ones actually present):
#   - GNOME apps / input engines / NM plugins / Exchange support
#   - malcontent-control: standalone parental-controls GUI
#     (the "malcontent" core stays: hard dep of gnome-control-center,
#      removing it cascades into gnome-shell and the whole desktop)
#   - nodejs22 (+ npm): nothing requires it, saved ~169 MiB
#   - xsel: orfano (xclip rimosso anche lui, nessuno dei due serve)
#   - gcc/glibc-devel/kernel-headers/libxcrypt-devel: compile toolchain,
#     unused on an immutable system (use toolbox/distrobox to compile)
REMOVE=(
    gnome-tour
    ibus-anthy ibus-hangul ibus-m17n ibus-typing-booster ibus-libpinyin
    NetworkManager-adsl evolution-ews evolution-ews-core evolution-ews-langpacks
    gnome-shell-extension-background-logo
    malcontent-control
    nodejs22
    xsel
    gcc glibc-devel kernel-headers libxcrypt-devel
)
# NOTE: perl stays — stow (dotfiles) is a Perl program and needs it.
INSTALLED=()
for p in "${REMOVE[@]}"; do
    if dnf5 repoquery --installed --queryformat '%{name}\n' "$p" 2>/dev/null | grep -Fxq "$p"; then
        INSTALLED+=("$p")
    fi
done
if [ "${#INSTALLED[@]}" -gt 0 ]; then
    dnf5 remove -y "${INSTALLED[@]}"
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

# --- sshd NOT enabled on purpose ---------------------------------------------
# The base leaves sshd.service disabled (only the systemd-ssh-generator vsock/unix
# listeners are active). We do NOT enable it in the image, otherwise TCP/22 would
# be open by default on the deployed (immutable) target. Enable it manually on the
# target if needed (`systemctl enable --now sshd`). For bcvk VM testing, enable it
# inside the VM (see README "Test in VM").

# Remove disabled third-party repo files shipped by fedora-workstation-repositories
# (required by fedora-release-silverblue). Chrome is a Flatpak on the target, not rpm.
# Kept: fedora, fedora-updates, fedora-cisco-openh264, vscode.
rm -f /etc/yum.repos.d/rpmfusion-nonfree-*.repo \
    /etc/yum.repos.d/_copr:*PyCharm.repo \
    /etc/yum.repos.d/google-chrome.repo
