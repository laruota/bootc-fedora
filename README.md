# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:45`.
Build con podman; l'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora` e gli
aggiornamenti sulla target avvengono via `bootc upgrade`.

## Flusso di lavoro

1. **Build locale** — `make build` (immagine `localhost/bootc-fedora:latest`).
2. **Test in VM** — `bcvk ephemeral run-ssh localhost/bootc-fedora`.
3. **Pubblica su ghcr** — push su GitHub (CI) o `make push ORG=laruota`. Il package
   va reso **pubblico** per il pull anonimo usato dal deploy.
4. **Prima installazione sulla target** — genera un'ISO con `image-builder`
   (`bootc-generic-iso`; oppure un qcow2 per VM) e installa.
5. **Aggiornamenti** — sulla target: `bootc switch` al tag desiderato, poi
   `bootc upgrade`.

## Contenuto

- `Containerfile` — definizione dell'immagine (versione Fedora via `ARG FEDORA_VERSION`, unica fonte)
- `Makefile` — scorciatoie `make build` / `make lint` / `make shellcheck` / `make push`
- `scripts/setup.sh` — pacchetti da installare/rimuovere (aggiungi qui le tue utility)
- `scripts/vscode.sh` — installa Visual Studio Code dal repo RPM ufficiale
- `scripts/fonts.sh` — pulizia font internazionali (da validare in VM)
- `scripts/bootstrap-flatpaks.sh` — bootstrap flatpak di sistema sulla macchina target (copiato in `/usr/libexec/bootc-fedora` nell'immagine)
- `scripts/bootstrap-python.sh` — bootstrap di librerie Python nel profilo dell'utente via pip `--user` (copiato in `/usr/libexec/bootc-fedora`)
- `iso/` — container installer + configurazione per generare l'ISO con `image-builder` (`bootc-generic-iso`)

## Personalizzazioni attuali

- Aggiunti: neovim, zsh, btrfs-assistant, sushi, cheat (+ cheat-community-cheatsheets),
  dconf-editor, gnome-tweaks, seahorse, zenity, GraphicsMagick, Visual Studio Code,
  gh, git-gui, git-delta, qpdf, mat2, gstreamer1-plugin-openh264, solaar(+udev)
- **Flatpak sulla target** (~42 app via `bootstrap-flatpaks.sh`): Chrome, Obsidian, GIMP, LibreOffice,
  Inkscape, Foliate, Meld, Transmission, Flatseal, ExtensionManager, Remmina, Warehouse, Resources,
  Switcheroo, Decoder, Eyedropper, Gear Lever, Celluloid, Gitte, MailViewer, PDF Arranger, Xournal++,
  Gradia, gthumb, virt-viewer, + app GNOME (Calculator, Calendar, Characters, Decibels, FileRoller, FontViewer,
  Logs, Loupe, Maps, Papers, Snapshot, Solanum, TextEditor, baobab, Apostrophe, Shortwave, Curtail, MediaWriter)
- **Python**: pipx + python3-pip nell'immagine. Su immutabile si usa:
  `pipx install` per i tool CLI (`~/.local`) e `python3 -m venv` per i progetti
  (python3-pip abilita venv+pip out-of-the-box; non serve python3-venv su Fedora).
  Le lib degli script (pandas, openpyxl, pdfplumber) si installano
   sulla target con `/usr/libexec/bootc-fedora/bootstrap-python.sh` eseguito dall'utente che
   usa gli script (pip `--user --break-system-packages`; non usare `sudo`).
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

    make build                       # usa FEDORA_VERSION=45 di default
    make build FEDORA_VERSION=44     # override
    make shellcheck                  # lint degli script shell

## Test in VM

    sudo dnf install bcvk     # richiede KVM/qemu/virtiofsd
    bcvk ephemeral run-ssh localhost/bootc-fedora

Nota: sshd **non** è abilitato di default nell'immagine (per non aprire TCP/22 sulla
target). Per usare `run-ssh` devi abilitarlo dentro la VM, es.:

    bcvk ephemeral run localhost/bootc-fedora   # avvia la VM (console)
    # nella VM: systemctl enable --now sshd
    # poi da host: bcvk ssh localhost/bootc-fedora


## Pubblicazione su ghcr.io

L'immagine contenitore NON contiene chiavi LUKS (la crittografia è creata in locale
sulla target all'installazione).

La GitHub Action `.github/workflows/build.yml` builda e pubblica su
`ghcr.io/laruota/bootc-fedora:<FEDORA_VERSION>` (e `:latest`) a ogni push su `main`
e su `workflow_dispatch`. Entrambi sono tag **mutabili**: rappresentano il canale
Fedora corrente, non una release immutabile. Il package su GitHub **deve essere pubblico** per il pull
anonimo usato dal deploy (`bootc switch`): Packages → bootc-fedora → Settings →
Change visibility. Se resta privato, serve il login (vedi sotto).

Build manuale (stesso risultato della CI):

    make push ORG=laruota              # oppure: ./scripts/push.sh laruota
    podman pull ghcr.io/laruota/bootc-fedora:45   # verifica pull anonimo

## Prima installazione sulla target

### ISO (consigliato per il portatile)

Si usa **osbuild `image-builder`** con il tipo **`bootc-generic-iso`**: prende un
container "installer" e lo "esplode" in un'ISO avviabile **senza dnf/depsolve**
(niente problemi di repository). Sostituisce il vecchio `bootc-image-builder`
(`anaconda-iso`), ora archiviato e non compatibile con i repo dnf5.

**1) Container installer** — `iso/Containerfile` deriva dall'immagine bootc e
aggiunge Anaconda + gli strumenti richiesti (`xorriso`, `squashfs-tools`,
`isomd5sum`, `grub2-efi-x64-cdboot`) e la configurazione ISO
(`iso/iso.yaml`, `iso/interactive-defaults.ks`):

    make installer     # = sudo podman build -t localhost/bootc-fedora-installer:latest iso/

**2) Genera l'ISO** — basta **podman** (nessun RPM da installare): `make iso` usa il
container ufficiale `ghcr.io/osbuild/image-builder-cli:latest`.

    make iso           # = sudo podman run --privileged --rm \
                       #     -v /var/lib/containers/storage:/var/lib/containers/storage \
                       #     -v "$PWD/output:/output" \
                       #     ghcr.io/osbuild/image-builder-cli:latest \
                       #     build --bootc-ref localhost/bootc-fedora-installer:latest \
                       #           --bootc-default-fs btrfs bootc-generic-iso

(Alternativa senza container: `sudo dnf install image-builder osbuild osbuild-depsolve-dnf`
e poi `sudo image-builder build --bootc-ref ... --bootc-default-fs btrfs bootc-generic-iso`.)

L'ISO viene scritta in `output/` (il file `.iso` è ignorato da git). Al boot Anaconda
installa `ghcr.io/laruota/bootc-fedora:45` (configurato in `iso/interactive-defaults.ks`).
Per l'installazione **offline** aggiungi `--bootc-installer-payload-ref ghcr.io/laruota/bootc-fedora:45`.

**3) Scrivi su USB e installa:**

    lsblk
    sudo dd if=<file>.iso of=/dev/sdX bs=4M status=progress oflag=sync

#### Crittografia LUKS
- **Passphrase**: aggiungi un kickstart con `part ... --encrypted --passphrase=...`
  (es. `iso/luks.ks`, **non** committarlo con la passphrase vera) e passalo a
  `image-builder` (blueprint `[customizations.installer.kickstart]`).
- **TPM (sblocco automatico)**: installa senza cifratura, poi
  `bootc install to-disk --block-setup tpm2-luks`.

### qcow2 per VM (bcvk)

    bcvk to-disk --filesystem btrfs --format=qcow2 localhost/bootc-fedora output/bootc-fedora.qcow2

## Aggiornamenti sulla target

Per un sistema già installato (da ISO o qcow2), aggancia/aggiorna l'immagine dal registry:

    bootc switch ghcr.io/laruota/bootc-fedora:45
    bootc upgrade                # aggiornamenti futuri

Installazione con **disco criptato (LUKS)**:
- **TPM (nativo, sblocco automatico)**: `bootc install to-disk --block-setup tpm2-luks`
- **Passphrase (come Workstation)**: usa l'ISO con kickstart precedente, oppure spunta
  la crittografia durante l'installazione Anaconda.

## Note

- L'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora`: ogni push su `main`
  (o `workflow_dispatch`) ricostruisce e pubblica una nuova immagine; la target la
  riceve con `bootc upgrade` dopo `bootc switch`.
- **App GNOME**: papers, loupe, gnome-calendar, ecc. NON sono nell'immagine — sono
  flatpak installati sulla target via GNOME Software. `bootstrap-flatpaks.sh` aggiunge
  e verifica il remote **Flathub completo** (Chrome e app proprietarie); non aggiunge
  il remote `fedora`, che puo essere gia presente nella base:
  `sudo /usr/libexec/bootc-fedora/bootstrap-flatpaks.sh` (o `flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`)
  Flatpak di sistema → `/var/lib/flatpak`, aggiornamenti con `sudo flatpak update`.
- **malcontent**: il core è richiesto da `gnome-control-center` (non rimovibile);
  è stata rimossa solo l'app standalone `malcontent-control`.
- **zram**: già incluso nella base (`zram-generator-defaults`) — swap compresso in RAM,
  nessuna partizione di swap necessaria. Eccezione: l'ibernazione richiederebbe swap su disco.
- **cups**: tenuto il server (stampante anche USB passa da cupsd); cups-client è già presente.
- **nmcli**: presente (fa parte di NetworkManager).
- La pulizia font è sperimentale: verificarne l'effetto in VM prima di fidarsene.
- Bump di versione Fedora: cambiare `ARG FEDORA_VERSION` nel `Containerfile` (unica fonte; `make build` e `make push` la usano automaticamente).

## Licenza

GPL-3.0 — vedi [LICENSE](LICENSE).
