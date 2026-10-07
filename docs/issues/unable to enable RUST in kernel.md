Nothing in `meta-raspberry` is overriding your config. What's actually failing is Rust detection: Yocto can't find `bindgen`, so the kernel quietly drops `CONFIG_RUST`.

## What the logs show

**1. Your `rust.cfg` is applied, and it's applied last.**
In `../../work/tmp/work-shared/raspberrypi5/kernel-source/.kernel-meta/cfg/merge_config_build.log`:
```
Merging .kernel-meta/configs//./powersave.cfg        <- meta-raspberry
Merging .kernel-meta/configs//./android-drivers.cfg  <- meta-raspberry
Merging .kernel-meta/configs//./vc4graphics.cfg      <- meta-raspberry
Merging .kernel-meta/configs//./default-cpu-governor.cfg
Merging .kernel-meta/configs//./custom-features.cfg
Merging .kernel-meta/configs//./rust.cfg             <- yours, last = wins
Value of CONFIG_MODVERSIONS is redefined by fragment rust.cfg:
Previous value: CONFIG_MODVERSIONS=y
New value: # CONFIG_MODVERSIONS is not set          <- your change was applied
```
Then it reports `Value requested for CONFIG_RUST not in final .config`. The `# CONFIG_RUST depends on ...` lines after it look like a list of culprits, but they're only the full list of what `CONFIG_RUST` depends on, not the ones that failed.

**2. In the final `.config`, one dependency is missing:**
```
CONFIG_HAVE_RUST=y            OK (arm64 + 6.12)
CONFIG_RUSTC_VERSION=107800   OK, rustc 1.78 found
# CONFIG_MODVERSIONS is not set   OK
(no CONFIG_RUST_IS_AVAILABLE)     <- this is the one that fails
```
`RUST_IS_AVAILABLE` is set by the kernel script `scripts/rust_is_available.sh`. The config never records why it failed.

**3. I ran that script with Yocto's restricted `PATH` and got the reason:**
```
*** Rust bindings generator 'bindgen' could not be found.
exit=1
```
`/home/user/rust-kernel-tools/bin` doesn't exist, so the `cargo install ... --root ~/rust-kernel-tools` step was never done. When you test in your normal shell it can look fine, because it finds `/usr/bin/bindgen` (version 0.66.1, from Ubuntu). Yocto hides `/usr/bin` from its tasks, so the kernel build never sees that one.

## How to fix it

**1. Install bindgen where `local.conf` expects it:**
```bash
cargo install --locked --version 0.65.1 bindgen-cli --root ~/rust-kernel-tools
~/rust-kernel-tools/bin/bindgen --version    # bindgen 0.65.1
```
Don't point `RUST_KERNEL_BINDGEN_DIR` at `/usr/bin` to reuse the Ubuntu bindgen:
- The kernel script warns that versions **0.66.0 and 0.66.1** have a known bug unless patched.
- It would also expose every other tool in `/usr/bin` to the kernel build.

**2. Check it with the same PATH Yocto uses** (this should print nothing and exit 0):
```bash
cd work/tmp/work-shared/raspberrypi5/kernel-source
env -i PATH=/home/user/.rustup/toolchains/1.78.0-x86_64-unknown-linux-gnu/bin:/home/user/rust-kernel-tools/bin:/home/user/projects/iaca-os-yocto-minimal/work/tmp/hosttools \
  LIBCLANG_PATH=/usr/lib/llvm-18/lib RUSTC=rustc BINDGEN=bindgen CC=gcc \
  sh scripts/rust_is_available.sh; echo "exit=$?"
```

**3. Force the kernel to be configured again.** The values in `local.conf` haven't changed, so Yocto thinks the old config is still valid and would reuse it from its cache:
```bash
MACHINE=raspberrypi5 bitbake -c cleansstate linux-raspberrypi make-mod-scripts
MACHINE=raspberrypi5 bitbake linux-raspberrypi
grep -E "CONFIG_RUST=|RUST_IS_AVAILABLE" tmp/work/raspberrypi5-poky-linux/linux-raspberrypi/6.12.93+git/linux-raspberrypi5-standard-build/.config
#   expected: CONFIG_RUST_IS_AVAILABLE=y and CONFIG_RUST=y
```

## Two more things I noticed

- **The check you added to the kernel bbappend looks at the wrong files.** It runs during the kernel's `do_configure` but reads `${STAGING_KERNEL_BUILDDIR}/.config`. That file is from the *previous* build, because the kernel only copies it there after compiling. It also expects `rust/libcore.rmeta`, which is built later by `make-mod-scripts`, not by the kernel. So its warning said "not enabled" for an outdated reason, and once Rust works it may fail even though nothing is wrong. Check `${B}/.config` instead, or move the `libcore.rmeta` check into the module recipe.
- **The `CONFIG_GCC_PLUGIN_RANDSTRUCT ... not in final .config` warning is harmless.** That option doesn't exist in this configuration, so the extra "is not set" lines in `rust.cfg` only add noise. For 6.12 arm64, `rust.cfg` only needs `CONFIG_RUST=y` and `# CONFIG_MODVERSIONS is not set`.

**Tip for next time:** if `CONFIG_RUST` disappears, run `rust_is_available.sh` with Yocto's PATH, as in step 2. It gives the exact reason, which the config merge log never shows.
