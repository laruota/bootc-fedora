#!/usr/bin/env bash
# Install/remove packages for the custom bootc image.
# Runs inside the container build. Extend the lists below to customize.
set -euox pipefail

# --- Install packages -------------------------------------------------------
dnf5 install -y \
    android-tools \
    ansible \
    bat \
    btrfs-assistant \
    cheat \
    dconf-editor \
    fd-find \
    fzf \
    gnome-tweaks \
    GraphicsMagick \
    neovim \
    nnn \
    rclone \
    ripgrep \
    seahorse \
    syncthing \
    tldr \
    trash-cli \
    tree \
    virt-viewer \
    wl-clipboard \
    xclip \
    zenity \
    zoxide \
    zsh

# --- Remove packages --------------------------------------------------------
# Replace vim with neovim (vim may not be installed on Silverblue at all)
dnf5 remove -y vim-minimal vim-enhanced || true

# Unneeded GNOME apps / input engines / NM plugins / Exchange support
# (remove only the ones actually present)
REMOVE="gnome-tour \
    ibus-anthy ibus-hangul ibus-m17n ibus-typing-booster ibus-libpinyin \
    NetworkManager-adsl evolution-ews evolution-ews-core evolution-ews-langpacks \
    gnome-shell-extension-background-logo"
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