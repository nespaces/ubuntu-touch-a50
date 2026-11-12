# Ubuntu Touch on Samsung Galaxy A50 (SM-A505FN, Exynos 9610)

Work-in-progress port of Ubuntu Touch (UBports, Ubuntu 20.04) to the Galaxy A50 on top of
**Halium 11** and the **Mint** 4.14.194 kernel (FreshROMs `android-14.0`).
Not an official UBports port. Use at your own risk: you can lose data and soft-brick the device.

## Status

| Area | State |
|---|---|
| Kernel boots, Halium initramfs, systemd, LXC Android container | works |
| Display, GPU (Mali-G72), Lomiri UI | works, smooth |
| Touch | works |
| USB (usb-moded / MTP / RNDIS) | fix prepared (vendor USB init overlay), untested |
| Audio | DSP/amp firmware now built into the kernel, untested; `pulseaudio` still crashes with SIGSEGV |
| Volume keys | events reach the kernel, but depend on audio |
| Notch ("waterdrop") | status bar items overlap it; Lomiri in the 20.04 image has no notch support |
| Wi-Fi, Bluetooth, modem, camera, sensors | not working / not investigated |

Details and the full bring-up log: [`docs/NOTES.md`](docs/NOTES.md) (Russian), [`docs/PROJECT.md`](docs/PROJECT.md).

## Layout

- `kernel/halium.fragment` – config fragment merged over `exynos9610-a50_core_defconfig`
  (Halium options, SELinux as the active LSM in permissive mode, built-in audio firmware, LTO off, ...).
- `kernel/patches/0001-halium-a50.patch` – patches on top of FreshROMs
  `android_kernel_samsung_exynos9610_mint` (`bec0c2aff1ee`, branch `android-14.0`). Includes:
  EMS scheduler early-init guard (boot panic), `security/security.c` hook-chain fix (usercopy panic),
  **`hci_sock_create()` restored** (Samsung stubbed it out, BlueZ then crashed the kernel), Bluetooth
  `BUG_ON` removed, bring-up safety net (a plain reboot in the first 3 minutes goes to recovery),
  plus small fixes for building with clang 21. KernelSU is disabled via config (`CONFIG_KSU=n`).
- `tools/build-kernel.sh`, `tools/build-boot.sh` – out-of-tree clang build and boot.img packaging.
- `device/deviceinfo` – UBports-style device info.
- `overlay/userdata-system-data/` – files that must be placed in `/userdata/system-data/` on the phone
  (Ubuntu Touch keeps persistent copies of `/etc/systemd/system`, `/etc/udev/rules.d`, `/opt` there, so edits to the
  rootfs image do not take effect):
  - `66-halium-a50.rules` – `0666` on `binder/hwbinder/vndbinder/ion/mali0/...`. **Without this Lomiri aborts with
    `gralloc-mapper is missing` and the screen flickers in a loop.**
  - `50-halium-ignore-keys.conf` – logind ignores the power key until `repowerd` is up.
  - `opt/halium-overlay/vendor/etc/init/init.exynos9610.usb.rc` – empty overlay so Android does not create its own USB gadget.
  - `halium-livelog.service` – debug only, writes live logs to `/userdata/live`.

## Not included (on purpose)

- Partition backups, Samsung firmware, vendor/system images, rootfs/GSI images, logs. Extract
  `calliope_{sram,dram,iva}.bin` and `Tfa9872.cnt` from your own stock vendor image and put them in
  `kernel/mint/firmware/` before building.
- The kernel tree itself: clone the upstream repository at the commit above and apply the patch.

## Build (short)

```bash
git clone --depth 1 -b android-14.0 https://github.com/FreshROMs/android_kernel_samsung_exynos9610_mint kernel/mint
git -C kernel/mint submodule update --init --depth 1
git -C kernel/mint apply ../patches/0001-halium-a50.patch   # from the repo's kernel/patches
tools/build-kernel.sh && tools/build-boot.sh
```

Requires clang, ld.lld and aarch64 binutils. Back up `boot` (and everything else) before flashing; flash only from TWRP.
