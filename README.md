# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:44`.
Build locale con podman, nessun registry → aggiornamenti manuali.

## Contenuto

- `Containerfile` — definizione dell'immagine
- `scripts/setup.sh` — pacchetti da installare/rimuovere (aggiungi qui le tue utility)
- `scripts/vscode.sh` — installa Visual Studio Code dal repo RPM ufficiale
- `scripts/fonts.sh` — pulizia font internazionali (da validare in VM)
- `scripts/bootstrap-flatpaks.sh` — bootstrap flatpak di sistema sulla macchina target (copiato anche in `/usr/local/bin` nell'immagine)

## Personalizzazioni attuali

- Aggiunti: neovim, zsh, btrfs-assistant, sushi, cheat (+ cheat-community-cheatsheets),
  dconf-editor, gnome-tweaks, seahorse, zenity, GraphicsMagick, Visual Studio Code
- Python: pipx + python3-pip nell'immagine. Su immutabile si usa:
  `pipx install` per i tool CLI (`~/.local`) e `python3 -m venv` per i progetti
  (python3-pip abilita venv+pip out-of-the-box; non serve python3-venv su Fedora).
- Install con `install_weak_deps=False`: non vengono trascinate dipendenze deboli
  (nodejs22/npm, gcc, xsel, evince-djvu, snapper, btrfsmaintenance, tree-sitter-cli, ...);
  niente ansible né virt-viewer (usati via toolbox/flatpak).
- Rimossi: vim (→ neovim, con `vi` che punta a nvim), gnome-tour, ibus-* non usati (anthy/hangul/m17n/typing-booster/pinyin),
  NetworkManager-adsl, evolution-ews (+ core/langpacks), gnome-shell-extension-background-logo, malcontent-control,
  font di scritture non-Latine (CJK, arabo, indiano, ebraico, thai, ...) e langpacks non `it`/`en`.
  Restano i font core (Cantarell/GNOME, Noto Latin+emoji+simboli+math, Liberation, STIX).
- Rimossi i file repo di terze parti (rpmfusion, PyCharm, google-chrome); restano fedora/updates/openh264/vscode.
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
- **App GNOME**: papers, loupe, gnome-calendar, ecc. NON sono nell'immagine — sono
  flatpak installati sulla target via GNOME Software. Al primo avvio viene aggiunto
  il remote `fedora`; il remote **Flathub completo** (Chrome e app proprietarie) va
  aggiunto a mano una volta sulla target:
  `sudo /usr/local/bin/bootstrap-flatpaks.sh` (o `flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`)
  Flatpak di sistema → `/var/lib/flatpak`, aggiornamenti con `sudo flatpak update`.
- **malcontent**: il core è richiesto da `gnome-control-center` (non rimovibile);
  è stata rimossa solo l'app standalone `malcontent-control`.
- La pulizia font è sperimentale: verificarne l'effetto in VM prima di fidarsene.
- Bump di versione Fedora: cambiare il tag `:44` nel `Containerfile`.