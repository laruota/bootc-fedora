# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:44`.
Build con podman; l'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora` e gli
aggiornamenti sulla target avvengono via `bootc upgrade`.

## Flusso di lavoro

1. **Build locale** — `make build` (immagine `localhost/bootc-fedora:latest`).
2. **Test in VM** — `bcvk ephemeral run-ssh localhost/bootc-fedora`.
3. **Pubblica su ghcr** — push su GitHub (CI) o `make push ORG=laruota`. Il package
   va reso **pubblico** per il pull anonimo usato dal deploy.
4. **Prima installazione sulla target** — genera un'ISO con `bootc-image-builder`
   (oppure un qcow2 per VM) e installa.
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

    make build                       # usa FEDORA_VERSION=44 di default
    make build FEDORA_VERSION=43     # override
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
`ghcr.io/laruota/bootc-fedora:<FEDORA_VERSION>` (e `:latest`) a ogni push su `master`
e su `workflow_dispatch`. Entrambi sono tag **mutabili**: rappresentano il canale
Fedora corrente, non una release immutabile. Il package su GitHub **deve essere pubblico** per il pull
anonimo usato dal deploy (`bootc switch`): Packages → bootc-fedora → Settings →
Change visibility. Se resta privato, serve il login (vedi sotto).

Build manuale (stesso risultato della CI):

    make push ORG=laruota              # oppure: ./scripts/push.sh laruota
    podman pull ghcr.io/laruota/bootc-fedora:44   # verifica pull anonimo

## Prima installazione sulla target

### ISO (consigliato per il portatile)

`bootc-image-builder` **non** è nei repo Fedora come RPM: si usa il container
ufficiale (richiede podman su un host Fedora/RHEL). L'output finisce in
`./output/bootc-fedora-<tag>.iso` (ignorato da git tramite `*.iso`).

Il builder **non** fa il pull da solo e non ha un rootfs di default (Fedora), quindi:
- scarica prima l'immagine (`podman pull`), così la trova nello storage montato;
- passa `--rootfs btrfs`. Il `Containerfile` imposta già btrfs come default
  (`/usr/lib/bootc/install/50-bootc-fedora.toml`), quindi il flag è opzionale sulle
  immagini ricostruite; resta qui per quelle già pushate senza il default.

Se il package è **privato**, prima del pull fai il login in ghcr.io come root:
User = username GitHub; password = un Personal Access Token con scope `read:packages`
(non la password di GitHub). In alternativa rendi il package pubblico (vedi sopra).

    sudo podman login ghcr.io                       # solo se il package è privato
    sudo podman pull ghcr.io/laruota/bootc-fedora:44
    sudo podman run --rm -it --privileged \
      --security-opt label=type:unconfined_t \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      -v "$PWD/output":/output \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso --rootfs btrfs ghcr.io/laruota/bootc-fedora:44

Se l'immagine è solo locale (non pushato), usa `--local`:

    sudo podman run --rm -it --privileged \
      --security-opt label=type:unconfined_t \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      -v "$PWD/output":/output \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso --rootfs btrfs --local localhost/bootc-fedora:latest

In caso di lock rimasti da run interrotte (`acquiring lock ... file exists`), prima
identifica e rimuovi soltanto il container del builder coinvolto:

    sudo podman ps -a
    sudo podman rm -f <id-o-nome-del-builder>

`sudo podman system reset -f` rimuove l'intero storage Podman (immagini, container e
volumi inclusi) e non va usato come recovery ordinario per questo progetto.

#### Crittografia LUKS con passphrase (tipo Workstation)

Il builder installa in modo automatico, quindi per la cifratura serve un kickstart.
Crea un file `iso.ks` **solo locale** (non committarlo con la passphrase vera). Sostituisci
`sda` con il disco destinato all'installazione: i comandi seguenti cancellano solo quel disco.

    ignoredisk --only-use=sda
    clearpart --drives=sda --all --initlabel
    part / --fstype btrfs --grow --encrypted --passphrase=<tua-passphrase> --ondisk=sda

e poi (stessa forma di sopra, con `--kickstart`):

    sudo podman run --rm -it --privileged \
      --security-opt label=type:unconfined_t \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      -v "$PWD/output":/output \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso --rootfs btrfs --kickstart iso.ks ghcr.io/laruota/bootc-fedora:44

L'ISO installa con la root cifrata (`/boot` resta non cifrato, come su Workstation);
all'avvio chiede la passphrase. In alternativa, per LUKS con sblocco **automatico
via TPM**: installa senza kickstart, poi abilita LUKS a post-installazione con
`bootc install to-disk --block-setup tpm2-luks` su un secondo disco.

### qcow2 per VM (bcvk)

    bcvk to-disk --filesystem btrfs --format=qcow2 localhost/bootc-fedora output/bootc-fedora.qcow2

## Aggiornamenti sulla target

Per un sistema già installato (da ISO o qcow2), aggancia/aggiorna l'immagine dal registry:

    bootc switch ghcr.io/laruota/bootc-fedora:44
    bootc upgrade                # aggiornamenti futuri

Installazione con **disco criptato (LUKS)**:
- **TPM (nativo, sblocco automatico)**: `bootc install to-disk --block-setup tpm2-luks`
- **Passphrase (come Workstation)**: usa l'ISO con kickstart precedente, oppure spunta
  la crittografia durante l'installazione Anaconda.

## Note

- L'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora`: ogni push su `master`
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
