# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:44`.
Build locale con podman, nessun registry → aggiornamenti manuali.

## Contenuto

- `Containerfile` — definizione dell'immagine (versione Fedora via `ARG FEDORA_VERSION`, unica fonte)
- `Makefile` — scorciatoie `make build` / `make lint` / `make push`
- `scripts/setup.sh` — pacchetti da installare/rimuovere (aggiungi qui le tue utility)
- `scripts/vscode.sh` — installa Visual Studio Code dal repo RPM ufficiale
- `scripts/fonts.sh` — pulizia font internazionali (da validare in VM)
- `scripts/bootstrap-flatpaks.sh` — bootstrap flatpak di sistema sulla macchina target (copiato anche in `/usr/local/bin` nell'immagine)
- `scripts/bootstrap-python.sh` — bootstrap lib/tool Python via pip `--user` + pipx sulla target (copiato anche in `/usr/local/bin`)

## Personalizzazioni attuali

- Aggiunti: neovim, zsh, btrfs-assistant, sushi, cheat (+ cheat-community-cheatsheets),
  dconf-editor, gnome-tweaks, seahorse, zenity, GraphicsMagick, Visual Studio Code,
  gh, git-gui, git-delta, qpdf, mat2, gstreamer1-plugin-openh264, solaar(+udev)
- **Flatpak sulla target** (~42 app via `bootstrap-flatpaks.sh`): Chrome, Obsidian, GIMP, LibreOffice,
  Inkscape, Foliate, Meld, Transmission, Flatseal, ExtensionManager, Remmina, Warehouse, Resources,
  Switcheroo, Decoder, Eyedropper, Gear Lever, Celluloid, Gitte, MailViewer, PDF Arranger, Xournal++,
  gthumb, virt-viewer, + app GNOME (Calculator, Calendar, Characters, Decibels, FileRoller, FontViewer,
  Logs, Loupe, Maps, Papers, Snapshot, Solanum, TextEditor, baobab, Apostrophe, Shortwave, Curtail, MediaWriter)
- **Python**: pipx + python3-pip nell'immagine. Su immutabile si usa:
  `pipx install` per i tool CLI (`~/.local`) e `python3 -m venv` per i progetti
  (python3-pip abilita venv+pip out-of-the-box; non serve python3-venv su Fedora).
  Le lib degli script (pandas, openpyxl, pdfplumber) si installano
  sulla target con `sudo /usr/local/bin/bootstrap-python.sh` (pip `--user --break-system-packages`).
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

    make build                       # usa FEDORA_VERSION=44 di default
    make build FEDORA_VERSION=43     # override

## Test in VM

    sudo dnf install bcvk     # richiede KVM/qemu/virtiofsd
    bcvk ephemeral run-ssh localhost/bootc-fedora

## Immagine disco per la macchina target

    bcvk to-disk --filesystem btrfs --format=qcow2 localhost/bootc-fedora output/bootc-fedora.qcow2

## Pubblicazione su ghcr.io (aggiornamenti automatici)

L'immagine contenitore è pubblica e NON contiene chiavi LUKS (la crittografia è
creata in locale sulla target all'installazione).

La GitHub Action `.github/workflows/build.yml` builda e pubblica su
`ghcr.io/<owner>/bootc-fedora:<FEDORA_VERSION>` (e `:latest`) a ogni push su
`master` e su `workflow_dispatch`. Per il pull anonimo (richiesto dal deploy
con `bootc switch`) imposta il package come **pubblico** su GitHub
(Packages → bootc-fedora → Settings → Change visibility), altrimenti resta
privato insieme alla repo.

Build manuale (stesso risultato della CI):

    make push ORG=<owner>              # oppure: ./scripts/push.sh <owner>
    podman pull ghcr.io/<owner>/bootc-fedora:44   # verifica pull anonimo

## Deploy (macchina target)

Installazione con **disco criptato (LUKS)** — come il tuo portatile:
- **TPM (nativo, sblocco automatico)**: `bootc install to-disk --block-setup tpm2-luks`
- **Passphrase (come Workstation)**: ISO Anaconda (`bootc-image-builder --type iso`)
  e spunta la crittografia durante l'installazione

Poi aggancia l'immagine dal registry:

    bootc switch ghcr.io/<org>/bootc-fedora:44
    bootc upgrade                # aggiornamenti futuri

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
- **zram**: già incluso nella base (`zram-generator-defaults`) — swap compresso in RAM,
  nessuna partizione di swap necessaria. Eccezione: l'ibernazione richiederebbe swap su disco.
- **cups**: tenuto il server (stampante anche USB passa da cupsd); cups-client è già presente.
- **nmcli**: presente (fa parte di NetworkManager).
- La pulizia font è sperimentale: verificarne l'effetto in VM prima di fidarsene.
- Bump di versione Fedora: cambiare `ARG FEDORA_VERSION` nel `Containerfile` (unica fonte; `make build` e `make push` la usano automaticamente).