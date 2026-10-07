# Vibe Instructions

Rules:
1. Never commit or add file (never git write action)
2. Never use `bitbake` command
3. If the prompt starts with "chat:", don't edit anything. Show the response in the console.

## Context
This is a **Yocto Project** build using **Scarthgap (poky)**. Target **MACHINE=raspberrypi5**.

Current work focuses on **iaca-os**:
- Distro config: `layers/meta-iaca/conf/distro/iaca-os.conf`
- Image recipe: `layers/meta-iaca/recipes-core/images/iaca-os-image-minimal.bb`
