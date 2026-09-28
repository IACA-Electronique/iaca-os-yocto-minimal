# Raspberry Pi A/B Redundant Partitioning Guide

This document outlines the architecture, prerequisites, and operational workflow for setting up a robust **A/B partition scheme** on Raspberry Pi (Compute Module 4, Raspberry Pi 4, and Raspberry Pi 5) using Yocto Project and the official Raspberry Pi EEPROM `tryboot` mechanism.

---

## 🎯 Purpose & Overview

An A/B partition setup provides **high availability and fail-safe over-the-air (OTA) system updates**. By maintaining two independent system slots (Slot A and Slot B):

- **Zero Downtime Updates:** The system writes and validates new firmware/rootfs in the inactive slot while running normally on the active slot.
- **Automatic Fallback:** If the updated slot fails to boot or crashes during startup, the hardware bootloader automatically reverts to the previously working slot on the next reboot.
- **Prevented Bricking:** System integrity is preserved even during unexpected power loss during updates.

---

## 📐 Partition Layout

The storage media (SD card, eMMC, or NVMe) is partitioned into two distinct boot/root pairs:

| Partition | Name | Filesystem | Mount Point | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`p1`** (`/dev/mmcblk0p1`) | **Boot A** | FAT32 | `/boot` | Kernel, DTBs, overlays, `cmdline.txt`, and `autoboot.txt` |
| **`p2`** (`/dev/mmcblk0p2`) | **Boot B** | FAT32 | *Unmounted* | Kernel, DTBs, overlays, and `cmdline.txt` for Slot B |
| **`p3`** (`/dev/mmcblk0p3`) | **Rootfs A** | ext4 / squashfs | `/` | Active Root Filesystem (Slot A) |
| **`p4`** (`/dev/mmcblk0p4`) | **Rootfs B** | ext4 / squashfs | *Unmounted* | Redundant Root Filesystem (Slot B) |
| *(Optional `p5`)* | **Data** | ext4 | `/data` | Persistent user data shared between Slot A and Slot B |

---

## ⚙️ Prerequisites

### 1. Yocto Configuration (`local.conf`)

Add `raspi-utils` (which provides the `vcmailbox` utility) to your target image:

```bitbake
IMAGE_INSTALL:append = " raspi-utils"
```

### 2. Linux Kernel Configuration

Ensure the kernel is configured with VideoCore Mailbox and firmware interface support enabled so userspace can communicate with the VideoCore bootloader:

```ini
# Raspberry Pi VideoCore Mailbox & Firmware Interface
CONFIG_BCM_VCIO=y
CONFIG_BCM2835_MBOX=y
CONFIG_RASPBERRYPI_FIRMWARE=y
```

> **Note:** These options expose `/dev/vcio`, allowing the `vcmailbox` command to set the one-time reboot register (`tryboot` flag).

---

## 🗂️ Configuration Files

### 1. Partition 1 (Boot A)

Boot Partition A acts as the primary bootloader configuration source and must contain `autoboot.txt`.

#### `autoboot.txt` (on Partition 1)

```ini
[all]
tryboot_a_b=1
boot_partition=1

[tryboot]
boot_partition=2
```

**Key Parameters Explained:**
- `tryboot_a_b=1`: Instructs the Raspberry Pi bootloader to parse the `[tryboot]` section when the tryboot flag is set in the mailbox.
- `boot_partition=1`: Default boot partition loaded during standard boot cycles (Partition 1).
- `[tryboot] boot_partition=2`: Target partition loaded when a one-shot `tryboot` is requested (Partition 2).

#### `cmdline.txt` (on Partition 1)

Points the kernel to mount Rootfs A (`p3`):

```text
console=serial0,115200 console=tty1 root=/dev/mmcblk0p3 rootfstype=ext4 rootwait rw
```

---

### 2. Partition 2 (Boot B)

Boot Partition B holds the redundant kernel and device tree blobs for Slot B. It does not require `autoboot.txt`.

#### `cmdline.txt` (on Partition 2)

Points the kernel to mount Rootfs B (`p4`):

```text
console=serial0,115200 console=tty1 root=/dev/mmcblk0p4 rootfstype=ext4 rootwait rw
```

---

## 🚀 Operating Workflow

```
+-------------------------------------------------------------+
|                     Running on Slot A                       |
|         (Boot partition: p1 / Rootfs partition: p3)         |
+-------------------------------------------------------------+
                              |
                              | 1. Install update to p2 & p4
                              v
+-------------------------------------------------------------+
|                  Set Tryboot Flag in EEPROM                 |
|            $ vcmailbox 0x00038064 4 0 1 && reboot           |
+-------------------------------------------------------------+
                              |
                              | 2. Rebooting...
                              v
+-------------------------------------------------------------+
|                      Tryboot Execution                      |
|           Bootloader loads Slot B (p2 / Rootfs p4)          |
+-------------------------------------------------------------+
               /                               \
              / (Boot OK / Validated)           \ (Crash / Power Loss / Watchdog)
             v                                   v
+-----------------------------+     +-----------------------------+
|  Slot B Confirmed Working   |     |    Automatic Fallback       |
|  Update autoboot.txt to     |     |    Next reboot reverts to   |
|  make Slot B the default    |     |    Slot A (p1 / p3) safely  |
+-----------------------------+     +-----------------------------+
```

### 1. Triggering a One-Time Jump to Slot B

To test an update or boot into Partition B, instruct the firmware to set the `tryboot` flag and reboot:

```bash
# Set tryboot register via VideoCore Mailbox
vcmailbox 0x00038064 4 0 1

# Reboot the device
reboot
```

- **Tag `0x00038064` (`SET_REBOOT_FLAGS`):** Sends a request to the VideoCore firmware mailbox with bit `0` set to `1` (indicating a tryboot request).
- **Firmware Reaction:** On reboot, the bootloader reads the `[tryboot]` section of `autoboot.txt` on Partition 1 and loads files from `boot_partition=2`.

### 2. Fallback Mechanism

- The `tryboot` flag is **one-shot and volatile**.
- If Slot B boots successfully, the health-check daemon (or OTA updater such as RAUC) validates system health and can update `autoboot.txt` to make Slot B permanent.
- If Slot B hangs, encounters a kernel panic, or triggers a hardware watchdog reset before confirmation, the system reboots cleanly back into Slot A (`boot_partition=1`).

---

## 🔍 Verification & Troubleshooting

- **Check device node presence:**
  ```bash
  ls -l /dev/vcio
  ```
  If `/dev/vcio` is missing, verify that `CONFIG_BCM_VCIO` and `CONFIG_RASPBERRYPI_FIRMWARE` are enabled in your kernel.

- **Check active root partition:**
  ```bash
  cat /proc/cmdline
  ```

---

## 📚 References & Further Reading

- [Raspberry Pi Documentation – autoboot.txt & tryboot](https://www.raspberrypi.com/documentation/computers/config_txt.html#autoboot-txt)
- [Bootlin Guide: Safe updates using RAUC on Raspberry Pi](https://bootlin.com/blog/safe-updates-using-rauc-on-raspberry-pi-5/)
- [Raspberry Pi Firmware Mailbox Property Interface](https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface)
