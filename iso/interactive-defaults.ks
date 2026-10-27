# Anaconda interactive defaults for the bootc-fedora installer ISO.
# Tells Anaconda which bootc container to install.
#
# ATTENZIONE: il tag `:45` va cambiato insieme alla riga FROM del Containerfile
# quando si bumpa la versione Fedora. `make installer` (e quindi `make iso`)
# verifica la coerenza e si ferma se i due divergono.
#
# Online install (Anaconda pulls the image, needs network):
bootc --source-imgref registry:ghcr.io/laruota/bootc-fedora:45 --target-imgref ghcr.io/laruota/bootc-fedora:45
#
# Offline install: pass
#   --bootc-installer-payload-ref ghcr.io/laruota/bootc-fedora:45
# to `image-builder build` (the image is embedded in the ISO and copied from the
# host's container storage into the squashfs), then use e.g.:
# bootc --source-imgref containers-storage:ghcr.io/laruota/bootc-fedora:45 --target-imgref ghcr.io/laruota/bootc-fedora:45
