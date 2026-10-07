DESCRIPTION = "Overlay initramfs image"

LICENSE = "MIT"

inherit core-image

IMAGE_FSTYPES = "cpio.gz"
IMAGE_FEATURES = ""
DISTRO_FEATURES = "overlayfs"

PACKAGE_INSTALL = "\
    base-files \
    base-passwd \
    busybox \
    initramfs-files \
    ${ROOTFS_BOOTSTRAP_INSTALL} \
"

export IMAGE_BASENAME = "overslay-initramfs-image"