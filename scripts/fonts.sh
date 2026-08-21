#!/usr/bin/env bash
# Remove unneeded international fonts / language packs.
# Keeps the core font set (Latin, GNOME UI, emoji, math/symbols) plus it/en.
# Validate in a VM before relying on this.
set -euox pipefail

# --- 1. Drop language packs we don't use --------------------------------------
# langpacks-* pulls per-locale fonts, dictionaries and GUI applications.
# Keep Italian and English (including their core-/fonts- sub-packages).
REMOVE=$(dnf5 repoquery --installed 'langpacks-*' 2>/dev/null \
    | grep -vE '^langpacks-(core-)?(fonts-)?(it|en)-0:' || true)
if [ -n "$REMOVE" ]; then
    # shellcheck disable=SC2086
    dnf5 remove -y $REMOVE
fi

# --- 2. Compute everything to drop from the default font set -------------------
# Fedora ships per-script fonts through metapackages:
#   default-fonts-cjk-*   -> Chinese / Japanese / Korean
#   default-fonts-other-* -> Arabic, Hebrew, Bengali, Devanagari, Thai, ...
#   default-fonts-<cc>    -> per-locale fonts (ur, my, si, bo, hi, fa, ...)
# The core set (Latin, GNOME, emoji, math/symbols) is kept.

# a) default-fonts metapackages, except the core-* ones
REMOVE=$(dnf5 repoquery --installed 'default-fonts-*' 2>/dev/null \
    | grep '^default-fonts-' | grep -v '^default-fonts-core-' || true)

# b) every google-noto-* font except the core Latin / symbols / math / emoji set.
#    google-noto-fonts-common MUST stay: it is shared data required by every
#    Noto font we keep (removing it cascades into fontconfig and breaks the OS).
KEEP='^(google-noto-fonts-common|google-noto-(sans|serif|sans-mono)(-vf)?-fonts|google-noto-sans-symbols-2-fonts|google-noto-sans-symbols-vf-fonts|google-noto-sans-math-fonts|google-noto-(color-)?emoji-fonts)-0:'
REMOVE="$REMOVE
$(dnf5 repoquery --installed 'google-noto-*' 2>/dev/null | grep -vE "$KEEP" || true)"

# c) other script fonts pulled in by the metapackages above or orphaned
REMOVE="$REMOVE
paktype-naskh-basic-fonts
sil-abyssinica-fonts sil-nuosu-fonts sil-padauk-fonts
smc-meera-fonts
thai-scalable-fonts-common thai-scalable-waree-fonts
jomolhari-fonts khmer-os-system-fonts
lohit-assamese-fonts lohit-bengali-fonts lohit-devanagari-fonts
lohit-gujarati-fonts lohit-kannada-fonts lohit-odia-fonts
lohit-tamil-fonts lohit-telugu-fonts
rit-rachana-fonts madan-fonts
pt-sans-fonts"

# d) remove everything at once so cross-dependencies resolve cleanly
REMOVE=$(printf '%s\n' "$REMOVE" | sed '/^$/d' | sort -u | tr '\n' ' ')
if [ -n "$REMOVE" ]; then
    # shellcheck disable=SC2086
    dnf5 remove -y $REMOVE
fi