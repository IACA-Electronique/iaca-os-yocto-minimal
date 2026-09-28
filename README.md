<section style="display: flex; flex-direction: column; align-items: center;">

# IACA OS Yocto minimal securised

![Docker](https://img.shields.io/badge/docker-257bd6?style=flat&logo=docker&logoColor=white)
![Yocto](https://img.shields.io/badge/Yocto-8A2BE2)
[![Pocky version](https://img.shields.io/badge/Poky-scarthgap-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Minimal Yocto image recipe for IACA-OS with a securised layer.

</section>

## Purpose

This repository provides a minimal Yocto image recipe for IACA-OS, with a securised layer to enhance the security of the system.

### Security features

- [x] A/B partitions
- [ ] Encrypted filesystem
- [ ] Safe and secure OTA Updates

#### Why is the secure boot missing?

Secure boot is a security feature that ensures the integrity and authenticity of the software running on a computer.
The problem it's that secure boot setup depends on the hardware and the firmware of the device. It's not possible to provide a generic solution for all devices.

## ⚠️ Requirements

- Minimum 140 GB of free disk
- At least 32 GB of RAM
- Ubuntu 24.04 (LTS)

> Complete YOCTO requirements informations available on the [official documentation](https://docs.yoctoproject.org/ref-manual/system-requirements.html#system-requirements)

### Dependencies

```bash
sudo apt-get install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd
```

## 🛠️ Development

### Test that the repository works well

```bash
cd poky
source oe-init-build-env
bitbake core-image-minimal
```

### Build minimal image for the device

```bash
cd poky
source oe-init-build-env ../work
MACHINE=<machine> bitbake core-image-minimal
```

> Replace `<machine>` by `raspberrypi4-64` or `raspberrypi5`.

## 📜 License

This project is licensed under the terms of the **GNU General Public License v3.0**.

See the [LICENSE](LICENSE) file for the full text.

---

<div align="center">
  <p>Powered by <a href="https://iaca-electronique.com">IACA Electronique</a></p>
</div>