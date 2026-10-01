SUMMARY = "IACA Watchdog - Rust-based system watchdog service"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-watchdog"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

# Git repository for the Rust source code
SRC_URI = "git://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-watchdog.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

# Inherit cargo classes for Rust build support
inherit cargo cargo-update-recipe-crates

require ${BPN}-crates.inc

S = "${WORKDIR}/git"
B = "${S}"

# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS = "--release -Znext-lockfile-bump"