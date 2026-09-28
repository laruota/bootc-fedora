# Anaconda interactive defaults for the bootc-fedora installer ISO.
# Tells Anaconda which bootc container to install.
#
# Online install (Anaconda pulls the image, needs network):
bootc --source-imgref registry:ghcr.io/laruota/bootc-fedora:45 --target-imgref ghcr.io/laruota/bootc-fedora:45
#
# Offline install: pass
#   --bootc-installer-payload-ref ghcr.io/laruota/bootc-fedora:45
# to `image-builder build` (the image is embedded in the ISO and copied from the
# host's container storage into the squashfs), then use e.g.:
# bootc --source-imgref containers-storage:ghcr.io/laruota/bootc-fedora:45 --target-imgref ghcr.io/laruota/bootc-fedora:45
