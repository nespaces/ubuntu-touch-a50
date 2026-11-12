# Ubuntu Touch for Samsung Galaxy A50 - v0.1.0-alpha

Unofficial port of Ubuntu Touch (UBports, Ubuntu 20.04, Lomiri) to the **Samsung Galaxy A50 (SM-A505F / SM-A505FN, Exynos 9610)**
on **Halium 11** and the Mint 4.14.194 kernel. **Alpha quality: it can lose your data. Back up first.**

## Requirements
- Galaxy A50 **SM-A505F or SM-A505FN**, unlocked bootloader, **TWRP** installed.
- The stock **Android 11** firmware (e.g. `A505FNPUS9CVJ2`) must be installed: the port uses its `vendor` partition.
- Everything on internal storage is erased (Format Data).

## Install (like any TWRP zip)
1. Copy `a50-ubuntu-touch-v0.1.0-alpha.zip` to the phone (or an SD card).
2. Boot to TWRP. **Wipe -> Format Data -> type `yes` (ext4).** This erases all data.
3. **Install** -> select the zip -> swipe. It flashes the boot image and writes the two system images to `/data` (several minutes).
4. **Reboot.** The first boot takes a few minutes, and the phone **reboots once by itself** while the A50 setup is applied. Be patient.

To go back to Android, flash the stock firmware with Odin.

## What works
Display and Lomiri UI, touch, Wi-Fi, Bluetooth (A2DP audio, mouse), audio and volume keys, system sounds, camera, USB (MTP, with the SD card shown as a second storage), GPS (needs sky view),
proximity sensor, notch / rounded-corner layout (portrait and landscape), screen rotation, NFC tag detection.

## Known issues / untested
- SIM and mobile data are untested (oFono is wired to the Android RIL, no SIM was available).
- Wi-Fi: only one station interface is used (a second one crashes the Samsung firmware).
- NFC: tags are detected; NDEF reading is untested. GPS may take minutes for the first fix.
- No sound from the Samsung audio HAL: audio uses a direct ALSA path.
- Fingerprint reader does not work (`biometryd` is masked: it aborts on every client query and would crash the Settings Security page).
- Keyboard vibration is a 10 ms pulse and is hardly noticeable; the motor itself works.
- Phone calls, SMS, mobile data, FM radio, some sensors: not tested.
- Full per-feature list: `CHECKLIST.md` / docs/CHECKLIST.md in the repository.
- The kernel contains Samsung audio firmware (`calliope_*`, `Tfa9872.cnt`) taken from the stock firmware.

## Source and build
Everything is open: https://github.com/nespaces/ubuntu-touch-a50 (kernel patches, overlays, tools, notes).
Kernel: FreshROMs `android_kernel_samsung_exynos9610_mint` + our patch. Rootfs/GSI images: UBports.

## Checksums
See `SHA256SUMS`.
