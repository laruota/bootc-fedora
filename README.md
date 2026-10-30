# bootc-fedora

Immagine bootc GNOME personalizzata, basata su `quay.io/fedora/fedora-silverblue:45`.
Build con podman; l'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora` e gli
aggiornamenti sulla target avvengono via `bootc upgrade`.

## Flusso di lavoro

1. **Build locale** — `make build` (immagine `localhost/bootc-fedora:latest`).
2. **Test in VM** — `bcvk ephemeral run-ssh localhost/bootc-fedora`.
3. **Pubblica su ghcr** — push su GitHub (CI) o `make push ORG=laruota`. Il package
   va reso **pubblico** per il pull anonimo usato dal deploy.
4. **Prima installazione sulla target** — la via più corta è installare
   Silverblue ufficiale e fare il rebase su questa immagine; in alternativa
   genera un'ISO con `image-builder` (`bootc-generic-iso`) o un qcow2 per VM.
5. **Aggiornamenti** — sulla target: `bootc switch` al tag desiderato, poi
   `bootc upgrade`.
6. **Ripiego** — se qualcosa non va, la target si riporta a Silverblue stock con
   `bootc switch`, senza reinstallare: vedi "Tornare a Silverblue".

## Contenuto

- `Containerfile` — definizione dell'immagine (base Fedora `45` nella riga `FROM`)
- `Makefile` — scorciatoie `make build` / `make lint` / `make shellcheck` / `make smoke` / `make push` / `make installer` / `make iso` / `make verify`
- `scripts/setup.sh` — pacchetti da installare/rimuovere (aggiungi qui le tue utility)
- `scripts/base-ref.sh` — legge la base dal `Containerfile` (`ref`, `version`); usato da Makefile e workflow
- `scripts/vscode.sh` — installa Visual Studio Code dal repo RPM ufficiale
- `scripts/fonts.sh` — pulizia font internazionali (da validare in VM)
- `scripts/bootstrap-flatpaks.sh` — bootstrap flatpak di sistema sulla macchina target (copiato in `/usr/libexec/bootc-fedora` nell'immagine)
- `scripts/bootstrap-python.sh` — bootstrap di librerie Python nel profilo dell'utente via pip `--user` (copiato in `/usr/libexec/bootc-fedora`)
- `iso/` — container installer + configurazione per generare l'ISO con `image-builder` (`bootc-generic-iso`)

## Personalizzazioni attuali

- Aggiunti (RPM): neovim, zsh, btrfs-assistant, sushi, gnome-tweaks, seahorse, zenity,
  GraphicsMagick, Visual Studio Code, gh, git-gui, git-delta, qpdf, mat2,
  gstreamer1-plugin-openh264, solaar(+udev), virt-viewer, android-tools, bat, chezmoi,
  fd-find, fzf, nmap, nnn, pipx, podman-compose, python3-pip, ripgrep, syncthing,
  tldr, tmux, trash-cli, tree, wl-clipboard, zoxide
- **Flatpak sulla target** (~43 app via `bootstrap-flatpaks.sh`): Chrome, Obsidian, GIMP, LibreOffice,
  Inkscape, Foliate, Meld, Transmission, Flatseal, ExtensionManager, Remmina, Warehouse, Resources,
  Switcheroo, Decoder, Eyedropper, dconf-editor, Gear Lever, Celluloid, Gitte, MailViewer, PDF Arranger,
  Xournal++, Gradia, gthumb, + app GNOME (Calculator, Calendar, Characters, Decibels, FileRoller, FontViewer,
  Logs, Loupe, Maps, Papers, Snapshot, Solanum, TextEditor, baobab, Apostrophe, Shortwave, Curtail, MediaWriter)
- **Python**: pipx + python3-pip nell'immagine. Su immutabile si usa:
  `pipx install` per i tool CLI (`~/.local`) e `python3 -m venv` per i progetti
  (python3-pip abilita venv+pip out-of-the-box; non serve python3-venv su Fedora).
  Le lib degli script (pandas, openpyxl, pdfplumber) si installano
   sulla target con `/usr/libexec/bootc-fedora/bootstrap-python.sh` eseguito dall'utente che
   usa gli script (pip `--user --break-system-packages`; non usare `sudo`).
- Install con `install_weak_deps=False`: non vengono trascinate dipendenze deboli
  (gcc, xsel, evince-djvu, snapper, btrfsmaintenance, tree-sitter-cli, ...);
  niente ansible (usato via toolbox).
- Rimossi: vim (→ neovim, con `vi` che punta a nvim), gnome-tour, ibus-* non usati (anthy/hangul/m17n/typing-booster/pinyin),
  NetworkManager-adsl, evolution-ews (+ core/langpacks), gnome-shell-extension-background-logo, malcontent-control,
  font di scritture non-Latine (CJK, arabo, indiano, ebraico, thai, ...) e langpacks non `it`/`en`.
  Restano i font core (Cantarell/GNOME, Noto Latin+emoji+simboli+math, Liberation, STIX).
- Rimossi i file repo di terze parti (rpmfusion, PyCharm, google-chrome); restano fedora/updates/openh264/vscode.
- Kernel args di default dell'immagine (`/usr/lib/bootc/kargs.d/00-desktop.toml`): `rhgb quiet`,
  necessari per il prompt **grafico** della passphrase LUKS all'avvio (senza `rhgb` plymouth resta in
  modalità testo). Sono kargs bootc, quindi valgono anche "day 2" via `bootc upgrade`.
- SELinux abilitato/enforcing come su Silverblue; l'ISO non passa `selinux=0` (vedi "Prompt grafico LUKS e SELinux").
- Shell default per i nuovi utenti: zsh

## Build

    make build                       # builda la base del tag nella riga FROM del Containerfile
    make shellcheck                  # lint degli script shell

La versione Fedora **non** è un `--build-arg`: è il tag della riga `FROM`
(`quay.io/fedora/fedora-silverblue:45`), unica fonte di verità per build locale,
CI e `make push`. Per provare un'altra versione si cambia quel tag, non un
parametro. `make build` usa `--pull=newer`, così non riusa una base vecchia
dalla cache locale.

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
`ghcr.io/laruota/bootc-fedora` a ogni push su `main`, con un **rebuild
giornaliero** (`schedule`, 03:17 UTC) e su `workflow_dispatch`. Il rebuild
periodico è necessario perché gli RPM arrivano dai repository *al momento della
build*: senza ricostruzioni, `bootc upgrade` sulla target sarebbe un no-op e gli
aggiornamenti (es. VS Code) non arriverebbero mai. Il package su GitHub **deve
essere pubblico** per il pull anonimo usato dal deploy (`bootc switch`):
Packages → bootc-fedora → Settings → Change visibility. Se resta privato, serve
il login (vedi sotto).

### Tag

| Tag | Tipo | Uso |
|---|---|---|
| `:45` | mutabile | canale: è quello che segue `bootc upgrade` |
| `:latest` | mutabile | alias dell'ultima build della versione corrente |
| `:45-20261027` | riferimento per data | build di quel giorno (data UTC) |
| `:45-1a2b3c4` | riferimento per commit | ultima build di quel commit |

I tag mutabili servono al flusso quotidiano. I tag per data/commit sono comodi
per riconoscere una build, ma **non sono immutabili**: `:45-<sha>` viene
ripushato dal rebuild giornaliero dello stesso commit e `:45-<data>` a ogni
build di quel giorno. L'unico identificatore stabile è il digest:

    sudo bootc switch ghcr.io/laruota/bootc-fedora@sha256:<digest>

Il digest esatto è nella summary del job di build (e lo stampa `make push`).

### Base e aggiornamento

La riga `FROM` usa il **tag mobile** `quay.io/fedora/fedora-silverblue:45`: a ogni
rebuild (giornaliero, 03:17 UTC) si prendono la base e gli RPM correnti. Non c'è
pin per digest: quay.io elimina i manifest vecchi a ogni compose (≈ ogni giorno),
quindi un pin smetterebbe di risolvere con `manifest unknown`; e la build non
sarebbe comunque riproducibile bit-per-bit, perché gli RPM non sono pinnati.

Per la tracciabilità, la CI risolve il digest della base al momento della build e
lo scrive nelle label OCI dell'immagine (`org.opencontainers.image.base.name` e
`org.opencontainers.image.base.digest`); si leggono con:

    podman image inspect ghcr.io/laruota/bootc-fedora:45

Se serve **bloccare temporaneamente** una base (es. regressione upstream), si
sostituisce il tag con `quay.io/fedora/fedora-silverblue:45@sha256:…` nella riga
`FROM`, sapendo che quel pin vale solo fino alla compose successiva: per questo
non è il funzionamento normale.

### Firma

Ogni build pubblicata è firmata con **cosign keyless**: la firma è legata a
questo repository e a questo workflow tramite l'OIDC di GitHub Actions (nessuna
chiave da custodire) e finisce nel log pubblico di Sigstore. Serve a verificare
che l'immagine venga da questo repo, non a impedirne l'installazione.

L'enforcement sulla target (`--enforce-container-sigpolicy`) **non** è
configurato: richiederebbe una firma con chiave. Se un giorno serve, si aggiunge
un secret `SIGNING_SECRET` e il `policy.json` sulla target, senza cambiare il
resto del flusso.

Verifica da qualsiasi macchina:

    make verify                     # richiede cosign nel PATH
    cosign verify ghcr.io/laruota/bootc-fedora:45 \
      --certificate-identity https://github.com/laruota/bootc-fedora/.github/workflows/build.yml@refs/heads/main \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com

### Retention

Le versioni vecchie su GHCR **non** vengono cancellate da GitHub. Il workflow
`retention.yml` (domenica, 04:23 UTC) tiene le 210 versioni più recenti (≈ 1–2
mesi con la cadenza attuale, cache di build compresa). I canali `45` e `latest`
sono sempre dentro la finestra perché puntano alla build più recente; un canale
vecchio (es. `44`) sparisce quando invecchia oltre le 210 versioni. Il package è
pubblico, quindi storage e banda sono gratuiti: la pulizia serve a tenerlo
leggibile (e a non pagare se un giorno diventasse privato). Se l'action fallisce
con 403, il repo non ha il ruolo Admin sul package: passare un PAT con
`delete:packages` al suo posto.

Build manuale (stesso risultato della CI, ma **senza firma**: la firma la fa
solo il workflow):

    make push ORG=laruota              # oppure: ./scripts/push.sh laruota
    podman pull ghcr.io/laruota/bootc-fedora:45   # verifica pull anonimo

## Prima installazione sulla target

### Da Silverblue ufficiale, senza ISO

Se la macchina ha rete, l'ISO non serve: si installa Silverblue 45 ufficiale e
poi si passa a questa immagine con un rebase (la base è la stessa, quindi si
scarica solo il delta e `/home`/`/var` non si toccano).

```bash
# che cosa gestisce il sistema appena installato?
bootc status

# caso classico dell'ISO ufficiale: backend rpm-ostree
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/laruota/bootc-fedora:45

# se invece il sistema è già gestito da bootc
sudo bootc switch ghcr.io/laruota/bootc-fedora:45

sudo systemctl reboot
```

Da sapere:

- **Aggiornamenti**: comanda il backend installato → `rpm-ostree upgrade` se sei
  rimasto su rpm-ostree, `bootc upgrade` se il sistema è bootc. Su Fedora 45 i
  due convivono, ma non sono intercambiabili per il timer automatico; per capire
  quale gira:
  `systemctl status bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer`.
- **kargs `rhgb quiet`** (prompt LUKS grafico): vengono da
  `/usr/lib/bootc/kargs.d/00-desktop.toml`. Se dopo il riavvio non ci sono
  (`cat /proc/cmdline`), aggiungili:
  `sudo rpm-ostree kargs --append=rhgb --append=quiet`.
- **La config btrfs** in `/usr/lib/bootc/install/` vale solo per `bootc install`,
  non per un rebase: partizioni e LUKS restano quelli creati dall'installer.
- **Vantaggio**: il primo deployment resta Silverblue stock, quindi hai un
  rollback immediato (voce GRUB o `rpm-ostree rollback`) senza scaricare nulla.

L'ISO resta utile per installazioni **offline**, per installare un **digest
pinnato** e per preparare più macchine allo stesso modo.

### ISO (offline o install ripetibile)

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

    make iso           # = sudo podman run --privileged --rm --pull=newer \
                       #     --security-opt label=type:unconfined_t \
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

## Tornare a Silverblue (senza reinstallare)

Il sistema installato è **bootc**: cambiare immagine è un rebase in place, non
una reinstallazione. `/home` e `/var` (flatpak, container, dati) restano; `/usr`
viene sostituito in blocco; `/etc` viene rifuso in merge a 3 vie.

    # verso Silverblue stock
    sudo bootc switch quay.io/fedora/fedora-silverblue:45
    sudo reboot

    # e per tornare alla tua immagine
    sudo bootc switch ghcr.io/laruota/bootc-fedora:45
    sudo reboot

Il download è solo il delta (la base è la stessa), quindi pochi minuti e qualche
centinaio di MB. Se invece il problema è il deployment *nuovo* (non la rete),
basta il rollback, che non scarica nulla:

    sudo bootc rollback --apply    # oppure la voce di rollback nel menu GRUB

Il rollback riordina i deployment esistenti: `/etc` torna allo stato di quello
precedente (le modifiche fatte dopo non si portano dietro). bootc tiene due
deployment (corrente + precedente).

Cosa resta da sistemare dopo il ritorno a Silverblue stock, perché vive in `/etc`
e quindi sopravvive al cambio:

    # 1. shell di default: zsh non c'è su Silverblue stock
    sudo sed -i 's|^SHELL=.*|SHELL=/bin/bash|' /etc/default/useradd
    # 2. editor: punta a nvim, che non c'è
    sudo rm -f /etc/profile.d/50-editor.sh
    # 3. kargs rhgb/quiet: arrivano da /usr/lib/bootc/kargs.d, quindi spariscono
    #    (servono per il prompt LUKS grafico)
    sudo rpm-ostree kargs --append=rhgb --append=quiet

`LANG=it_IT.UTF-8` e `localtime` restano: sono impostazioni tue, non della base.

**Limite**: `bootc switch` richiede un sistema avviato. Se l'immagine non parte
affatto (installer, kernel, bootloader) resta il rollback da GRUB se esiste il
deployment precedente, altrimenti la ISO. Per questo conviene provare l'immagine
in VM (`bcvk`, sopra) e fare un rehearsal dello switch appena installato: così
sai già che la via di fuga funziona e quanto ci mette.

## Prompt grafico LUKS e SELinux

Con root cifrata la passphrase può essere chiesta da plymouth (GUI) oppure in
modalità testo. Il prompt **grafico** richiede `rhgb` (o `splash`) sulla command
line del kernel: senza, plymouth resta in modalità "details" (testo). L'immagine
imposta `rhgb quiet` di default in `/usr/lib/bootc/kargs.d/00-desktop.toml`,
quindi valgono anche "day 2" via `bootc upgrade`.

Su un sistema già installato dove appare il prompt testuale:

    sudo rpm-ostree kargs --append=rhgb --append=quiet
    # riavvia

Nota sul percorso ISO (`iso/iso.yaml`, `bootc-generic-iso`): gli argomenti GRUB
dell'installer **non** passano al sistema installato, tranne quelli in
`preserved_arguments` di Anaconda (`selinux`, `console`, ...). `rhgb`/`quiet`
non sono tra questi: per questo servono i `kargs.d` nell'immagine.

⚠️ **SELinux**: non usare `selinux=0` nel boot dell'installer. Disabilita SELinux
anche nel sistema installato (Anaconda lo preserva e bootc forza il target:
`SELinuxFinalState::ForceTargetDisabled`). Per riattivare SELinux su una macchina
già installata con `selinux=0`:

    sudo rpm-ostree kargs --delete=selinux=0
    sudo touch /.autorelabel      # forza il relabel al prossimo boot
    sudo systemctl reboot         # verifica con getenforce / sestatus

## Note

- L'immagine è pubblicata su `ghcr.io/laruota/bootc-fedora`: ogni push su `main`,
  il rebuild giornaliero (03:17 UTC) o `workflow_dispatch` ricostruisce e pubblica
  una nuova immagine con tag mutabili (`45`, `latest`) e riferimenti (`45-<data>`,
  `45-<sha>`), firmata con cosign; la target la riceve con `bootc upgrade` dopo
  `bootc switch`.
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
- Bump di versione Fedora: tag nella riga `FROM` del `Containerfile` più il tag
  in `iso/interactive-defaults.ks` (il Makefile controlla che coincidano).

## Licenza

GPL-3.0 — vedi [LICENSE](LICENSE).
