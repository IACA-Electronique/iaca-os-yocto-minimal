SUMMARY = "IACA OS Minimal Image"
DESCRIPTION = "Minimal image for IACA OS with essential packages"
LICENSE = "MIT"

EXTRA_IMAGE_FEATURES += " \
    debug-tweaks \
    package-management \
"

# Package installation
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " bash raspi-utils util-linux hello-rust rust-hello-mod colors i2c-tools"
IMAGE_INSTALL:append = " iaca-watchdog"


IMAGE_CLASSES += "image_types_iaca image_types_dir"
IMAGE_FSTYPES = "rpi-sdimg tar.gz dir iaca"

# Filesystem configuration
BOOT_SPACE = "128000"
IMAGE_ROOTFS_SIZE = "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

PACKAGE_CLASSES ?= "package_deb"

COMPATIBLE_MACHINE = "raspberrypi5|raspberrypi4"

INITRAMFS_IMAGE = "overlay-initramfs-image"
INITRAMFS_IMAGE_NAME = "${INITRAMFS_IMAGE}-${MACHINE}.rootfs"