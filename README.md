# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:44`.
Build locale con podman, nessun registry → aggiornamenti manuali.

## Contenuto

- `Containerfile` — definizione dell'immagine
- `scripts/setup.sh` — pacchetti da installare/rimuovere (aggiungi qui le tue utility)
- `scripts/vscode.sh` — installa Visual Studio Code dal repo RPM ufficiale
- `scripts/fonts.sh` — pulizia font internazionali (da validare in VM)

## Personalizzazioni attuali

- Aggiunti: neovim, zsh, btrfs-assistant,
  dconf-editor, gnome-tweaks, seahorse, zenity, GraphicsMagick, Visual Studio Code
- Rimossi: vim (→ neovim, con `vi` che punta a nvim), gnome-tour, ibus-* non usati (anthy/hangul/m17n/typing-booster/pinyin),
  NetworkManager-adsl, evolution-ews (+ core/langpacks), gnome-shell-extension-background-logo,
  font di scritture non-Latine (CJK, arabo, indiano, ebraico, thai, ...) e langpacks non `it`/`en`.
  Restano i font core (Cantarell/GNOME, Noto Latin+emoji+simboli+math, Liberation, STIX).
- Shell default per i nuovi utenti: zsh

## Build

    podman build -t localhost/bootc-fedora:latest .

## Test in VM

    sudo dnf install bcvk     # richiede KVM/qemu/virtiofsd
    bcvk ephemeral run-ssh localhost/bootc-fedora

## Immagine disco per la macchina target

    bcvk to-disk --format=qcow2 localhost/bootc-fedora output/bootc-fedora.qcow2

## Note

- Nessun registry → la target non riceve aggiornamenti automatici: per aggiornare,
  rebuild + re-flash dell'immagine. Se in futuro servirà `bootc upgrade`, basterà
  pubblicare l'immagine su ghcr.io/quay.io e fare `bootc switch`.
- La pulizia font è sperimentale: verificarne l'effetto in VM prima di fidarsene.
- Bump di versione Fedora: cambiare il tag `:44` nel `Containerfile`.