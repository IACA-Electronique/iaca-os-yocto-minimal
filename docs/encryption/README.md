# Encrypted Root Filesystem Guide

This document provides a comprehensive guide to building, configuring, provisioning, and troubleshooting an **encrypted root filesystem (LUKS)** using the custom initramfs in IACA OS.

---

## 🎯 Purpose & Overview

Full disk encryption ensures data confidentiality and security at rest by protecting all root filesystem contents—including proprietary applications, configuration files, credentials, and system logs—from unauthorized physical extraction or tampering.

### Key Features
- **Early-Boot Decryption:** Unlocks the root filesystem before launching the primary init system (`/sbin/init`).
- **Standard LUKS / dm-crypt:** Leverages Linux cryptographic subsystems (`cryptsetup`) for industry-standard encryption.
- **Flexible Deployment:** Integrates with both standalone and redundant A/B partitioning layouts.

---

## 🏗️ Architecture & Boot Sequence

When booting an encrypted system, the Linux kernel first mounts the bundled initramfs image, unlocks the encrypted block device, and transitions into the decrypted root filesystem.

```
+-------------------------------------------------------------+
|                     1. Kernel Boots                         |
|     Loads bundled initramfs (custom-initramfs-encryption)   |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                 2. Initramfs Execution (/init)              |
|   - Mounts /proc, /sys, /dev                                |
|   - Reads 'root=' and 'encryptkey=' from /proc/cmdline      |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                 3. LUKS Partition Unlocking                 |
|   - Runs cryptsetup luksOpen $ROOTDEV disk0                 |
|   - Creates decrypted mapper node: /dev/mapper/disk0        |
+-------------------------------------------------------------+
               /                               \
              / (Success)                       \ (Failure)
             v                                   v
+-----------------------------+     +-----------------------------+
|     4. Rootfs Transition    |     |    5. Diagnostic Shell      |
| - Mounts /dev/mapper/disk0  |     | - Prints diagnostic logs    |
|   to /newroot               |     | - Drops to interactive      |
| - Moves /proc, /sys, /dev   |     |   emergency /bin/sh shell   |
| - switch_root to /sbin/init |     +-----------------------------+
+-----------------------------+
```

---

## ⚙️ Yocto Build Configuration

Enabling the encrypted filesystem requires configuring the initramfs in your build environment.

### 1. Update `local.conf`

Add the following lines to your `conf/local.conf` (or distribution configuration) to bundle the encryption initramfs into the kernel:

```bitbake
# Enable Custom Encryption Initramfs
INITRAMFS_IMAGE = "custom-initramfs-encryption-image"
INITRAMFS_IMAGE_NAME = "${INITRAMFS_IMAGE}-${MACHINE}.rootfs"
INITRAMFS_IMAGE_BUNDLE = "1"
INITRAMFS_FSTYPES = "cpio.gz"
```

> **Note:** Setting `INITRAMFS_IMAGE_BUNDLE = "1"` bundles the initramfs directly into the kernel binary (`zImage` / `Image`), ensuring the decryption utilities are available immediately at boot.

### 2. Kernel Dependencies

Ensure your Linux kernel configuration includes device mapper and cryptographic cipher support:

```ini
CONFIG_BLK_DEV_DM=y
CONFIG_DM_CRYPT=y
CONFIG_CRYPTO_AES=y
CONFIG_CRYPTO_XTS=y
CONFIG_CRYPTO_SHA256=y
```

### 3. Build the Image

Build your target OS image or the initramfs standalone:

- **Build Target OS Image:**
  ```bash
  bitbake <target-image-name>
  ```

- **Build Initramfs Standalone (for testing/verification):**
  ```bash
  bitbake custom-initramfs-encryption-image
  ```

---

## 🔧 Bootloader Configuration (`cmdline.txt`)

The `/init` script in `custom-initramfs-encryption-image` expects two parameters on the kernel command line:

| Parameter | Required | Description | Example |
| :--- | :--- | :--- | :--- |
| `root=` | **Yes** | Target raw block device containing the LUKS partition | `root=/dev/mmcblk0p2` |
| `encryptkey=` | **Yes** | Passphrase used to unlock the LUKS volume | `encryptkey=MySecretKey123` |

### Example `cmdline.txt`

```text
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 encryptkey=MySecretKey123 rootwait rw
```

---

## 💾 Storage Provisioning (Deployment Side)

Before booting with encryption enabled, the storage device must be partitioned, formatted with LUKS, and populated with the root filesystem.

### Step 1: Format Partition with LUKS

On your host deployment machine (replace `/dev/sdX2` with your target root partition):

```bash
# Format the partition with LUKS (using matching passphrase)
sudo cryptsetup luksFormat --type luks2 /dev/sdX2
```

### Step 2: Open and Map Decrypted Device

```bash
sudo cryptsetup luksOpen /dev/sdX2 disk0
```

The decrypted volume will now be accessible at `/dev/mapper/disk0`.

### Step 3: Create Filesystem

Format the mapped device with ext4:

```bash
sudo mkfs.ext4 -L rootfs /dev/mapper/disk0
```

### Step 4: Populate Root Filesystem

Mount the decrypted device and extract the rootfs tarball generated by Yocto:

```bash
# Create temporary mount point
sudo mkdir -p /mnt/target_rootfs
sudo mount /dev/mapper/disk0 /mnt/target_rootfs

# Extract root filesystem archive (run as root to preserve permissions)
sudo tar -xf /path/to/build/tmp/deploy/images/<machine>/<image-name>-<machine>.rootfs.tar.gz -C /mnt/target_rootfs/

# Sync and unmount
sudo sync
sudo umount /mnt/target_rootfs
```

### Step 5: Close Mapped Device

```bash
sudo cryptsetup luksClose disk0
```

The storage medium is now ready to boot in the target hardware.

---

## 🔍 Verification & Troubleshooting

### Emergency Shell
If unlocking fails (due to incorrect key, invalid root partition, or filesystem issues), the `/init` script drops to an emergency shell (`/bin/sh`) with serial/console access enabled.

### Diagnostic Checklist
From the recovery shell, run the following commands to diagnose issues:

1. **Verify Block Devices:**
   ```sh
   ls -l /dev/mmcblk* /dev/sd* /dev/nvme*
   ```
2. **Inspect Kernel Command Line:**
   ```sh
   cat /proc/cmdline
   ```
3. **Check Device Mapper:**
   ```sh
   ls -l /dev/mapper
   ```
4. **Manual Unlock Test:**
   ```sh
   cryptsetup luksOpen /dev/mmcblk0p2 disk0
   ```

---

## 🔐 Security Best Practices

- **Production Key Storage:** Passing `encryptkey=` directly via `cmdline.txt` is convenient for development. For production environments, consider securing the key using a hardware Root of Trust, TPM 2.0, or secure hardware keystores.
- **A/B Partition Integration:** When combining encryption with redundant A/B partitioning, provision separate LUKS headers and keys for each root partition (Slot A and Slot B).

---

## 📚 References & Related Documentation

- [Custom Layer Documentation](../../layers/meta-custom/README.md)
- [Raspberry Pi A/B Redundant Partitioning Guide](../a_b%20partition/README.md)
- [cryptsetup & LUKS Documentation](https://gitlab.com/cryptsetup/cryptsetup)