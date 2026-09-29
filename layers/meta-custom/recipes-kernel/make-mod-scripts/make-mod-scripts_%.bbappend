# Kconfig is evaluated again by "make prepare" in kernel-build-artifacts:
# without rustc/bindgen in PATH, CONFIG_RUST is dropped and rust/ is not built,
# so out-of-tree Rust modules fail with "can't find crate for `core`".
inherit rust-kernel-toolchain