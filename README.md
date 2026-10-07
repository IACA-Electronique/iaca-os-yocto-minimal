<section style="display: flex; flex-direction: column; align-items: center;">

# IACA OS Yocto minimal

![Docker](https://img.shields.io/badge/docker-257bd6?style=flat&logo=docker&logoColor=white)
![Yocto](https://img.shields.io/badge/Yocto-8A2BE2)
[![Pocky version](https://img.shields.io/badge/Poky-scarthgap-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Minimal Yocto image recipe for IACA-OS.

</section>

* **Maintainer**: Julien FAURE <julien.faure@iaca-electronique.com>

## Purpose

This repository provides a minimal Yocto image recipe for IACA-OS.


### Documentations

* [A/B partition](docs/a_b%20partition/README.md)
* [Encrypted filesystem](docs/encryption/README.md)
* [Custom layer documentation](layers/meta-custom/README.md)
* [SysVInit](docs/sysvinit/README.md)

## ✅ Supported devices

| Device name         | Status               | `MACHINE`      |
|---------------------|----------------------|----------------|
| IACA-BOX revB - CM5 | ✅ Supported, Tested | `raspberrypi5` |
| IACA-BOX revB - CM4 | ✅ Supported         | `raspberrypi4` |


## 📦️ Build

### ⚠️ Requirements

- Minimum 140 GB of free disk
- At least 32 GB of RAM
- Ubuntu 24.04 (LTS)

> Complete YOCTO requirements informations available on the [official documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#system-requirements)

#### Dependencies

```bash
sudo apt-get install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd
```

##### Rust assets

```bash
# Install specific Rust toolchain version                                                                                                                                                                        
rustup install 1.78.0                                                                                                                                                                                            
rustup default 1.78.0                                                                                                                                                                                            
                                                                                                                                                                                                               
# Setup rust-kernel-tools for bindgen                                                                                                                                                                            
git clone https://github.com/Rust-for-Linux/rust-kernel-tools.git ~/rust-kernel-tools                                                                                                                            
cd ~/rust-kernel-tools                                                                                                                                                                                           
./download-bindgen.sh
```

> **IMPORTANT**: Minimal version for rustup (rustc) is `1.78.0` and binden is `0.64.0`

> **NOTE**: You could use `RUST_KERNEL_TOOLCHAIN` and `RUST_KERNEL_BINDGEN_DIR` variables in your `local.conf`
> file to override default rust assets location.

## 🛠️ Development

### Test that the repository works well

```bash
cd poky
source oe-init-build-env
bitbake iaca-os-image-minimal
```

### Build minimal image for the device

```bash
cd poky
source oe-init-build-env ../work
MACHINE=<machine> bitbake iaca-os-image-minimal.bb
```

> Replace `<machine>` by `raspberrypi4-64` or `raspberrypi5`.

___

## 📜 License

This project is licensed under the terms of the **GNU General Public License v3.0**.

See the [LICENSE](LICENSE) file for the full text.

---

<div align="center">
  <p>Powered by <a href="https://iaca-electronique.com">IACA Electronique</a></p>
</div>