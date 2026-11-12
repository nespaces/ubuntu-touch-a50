# Ubuntu Touch on Samsung Galaxy A50 (SM-A505FN, Exynos 9610)

Work-in-progress port of Ubuntu Touch (UBports, Ubuntu 20.04) to the Galaxy A50 on top of
**Halium 11** and the **Mint** 4.14.194 kernel (FreshROMs `android-14.0`).
Not an official UBports port. Use at your own risk: you can lose data and soft-brick the device.

## Download and install

**[Download v0.1.0-alpha (TWRP ZIP, 958 MB)](https://github.com/nespaces/ubuntu-touch-a50/releases/tag/v0.1.0-alpha)** — alpha, it can lose data.

1. Galaxy A50 **SM-A505F / SM-A505FN**, unlocked bootloader, TWRP, **stock Android 11** firmware installed (the port uses its `vendor` partition).
2. TWRP: **Wipe → Format Data → `yes`** (ext4), then **Install** the ZIP, then **Reboot**.
3. First boot takes several minutes and reboots once by itself. Nothing else to do.

Check the download with `SHA256SUMS` from the release page. To return to Android flash the stock firmware with Odin.

## Status (2026-11-12)

Full per-feature list in the UBports format: [docs/CHECKLIST.md](docs/CHECKLIST.md). Installable release: one TWRP-flashable ZIP (see Releases).

| Area | State |
|---|---|
| Kernel, Halium initramfs, systemd, LXC Android container | works |
| Display, GPU (Mali-G72), Lomiri UI | works, smooth |
| Touch, camera, Wi-Fi | work (Wi-Fi: only `wlan0` is managed by NetworkManager, a second STA interface crashes the SCSC firmware; `wlan0` is kept up by a small service) |
| USB (MTP, RNDIS, ssh) | works (kernel configfs patch + vendor USB init overlay; `usb_moded` runs with `-f` because Samsung reports a PC port as a charger, and the IDs in `usb-moded.d` are decimal because configfs parses `04e8` as octal) |
| Bluetooth | works: HCI socket bind/ioctl/getname/release restored in the kernel (Samsung stubbed them), `bluebinder` brings `hci0` up, discovery works, AirPods Pro (A2DP) and a mouse (UHID udev rule) verified. `bluebinder` is started once with `Restart=no` because a restart loop shuts the shared WLBT chip (and Wi-Fi) down |
| Audio | works: speaker via a direct ALSA sink on `hw:0,0` (ABOX RDMA0 -> UAIF2 -> TFA9872) with the mixer route from `/vendor/etc/mixer_paths.xml`; the Samsung audio HAL in pulse-droid is a stub (NULL `create_audio_patch`) and is not used. Small periods (512 frames) are needed because the ABOX `hw_ptr` is coarse |
| Proximity | SensorStatus reports near/far and the screen turns off at the ear during a call |
| GPS | Samsung GNSS initialized by `a50-gnss-init.service` before the Lomiri location service; `lomiri-location-service` runs with the GPS provider only (`zz-a50-gps-only.conf`): the default `remote::Provider` returned a wrong fixed position (Bergen) that weather apps used |
| Modem / SIM | oFono is bound to the Android IRadio 1.4 HAL through the binder plugin (both slots powered/online); not tested with a SIM yet |
| NFC | tags are detected (Samsung NFC HAL -> `nfcd` binder plugin, adapter `/nfc0`, MIFARE / ISO-DEP / NFC-DEP); NDEF reading is untested (needs an NTAG tag, a bank card has no NDEF so `NFC Tag Editor` reports `Unknown error`) |
| Volume keys, system sounds | work (needs AppArmor as major LSM + the `SO_PEERSEC` hook below) |
| Notch ("waterdrop") and rounded corners | works through a Lomiri QML overlay (`overlay/notch`): clock top-left, indicators right of the camera, expanded tabs below it |
| Memory leak (fixed) | `bluebinder` opened HCI sockets in a loop and Samsung's stubbed `hci_sock_release` leaked each one (~3 GB of `kmalloc-2048` in 40 s, then OOM / black screen). Fixed by restoring `hci_sock_create()`/`hci_sock_release()` |

Details and the full bring-up log: [`docs/NOTES.md`](docs/NOTES.md) (Russian), [`docs/PROJECT.md`](docs/PROJECT.md),
helper investigations in [`docs/codex`](docs/codex).

## Layout

- `kernel/halium.fragment` – config fragment merged over `exynos9610-a50_core_defconfig`
  (Halium options, AppArmor as the active LSM, built-in audio firmware, RFKILL, SLUB_DEBUG, LTO off, ...).
- `kernel/patches/0001-halium-a50.patch` – patches on top of FreshROMs
  `android_kernel_samsung_exynos9610_mint` (`bec0c2aff1ee`, branch `android-14.0`):
  EMS scheduler early-init guard (boot panic), `security/security.c` hook-chain fix (usercopy panic),
  **HCI socket code restored** (`hci_sock_create/release/bind/ioctl/getname` were stubbed out by Samsung; BlueZ then crashed or leaked the kernel), Bluetooth `BUG_ON` removed,
  **USB configfs gadget made stock-like** (Samsung's UEVENT mode parks functions in `gi->linked_func`, so usb-moded's bind failed with -EINVAL and looped),
  **AppArmor is the major LSM again, with a new `socket_getpeersec_stream` hook** (mainline 4.14 AppArmor lacks SO_PEERSEC for unix sockets, so D-Bus peers have no label and lomiri's media-hub aborts),
  bring-up safety net (a plain reboot in the first 3 minutes goes to recovery), plus small fixes for clang 21.
  KernelSU is disabled via config (`CONFIG_KSU=n`).
- `tools/build-kernel.sh`, `tools/build-boot.sh` – out-of-tree clang build and boot.img packaging.
- `device/deviceinfo` – UBports-style device info.
- `overlay/rootfs/` – files for the Ubuntu rootfs image:
  - `usr/share/halium-overlay/vendor/etc/init/vndservicemanager.rc` – runs the GSI `servicemanager` as vndservicemanager (the vendor binary aborts without kernel SELinux).
  - `usr/share/halium-overlay/vendor/etc/init/init.exynos9610.usb.rc` – empty overlay so Android does not create its own USB gadget
    (must be in the rootfs; `/opt/halium-overlay` is mounted too late).
  - `etc/pulse/touch.pa` – `module-droid-discover` commented out; `etc/pulse/daemon.conf.d/50-halium-debug.conf` – verbose pulse log.
  - `etc/systemd/logind.conf.d/50-halium-ignore-keys.conf` – logind ignores the power key until `repowerd` is up.
- `overlay/userdata-system-data/` – files that go to `/userdata/system-data/` on the phone. Ubuntu Touch keeps persistent copies of
  `/etc/systemd/system`, `/etc/udev/rules.d` and `/opt` there, so edits to the rootfs image do not take effect for them:
  - `66-halium-a50.rules` – `0666` on `binder/hwbinder/vndbinder/ion/mali0/...`. **Without this Lomiri aborts with
    `gralloc-mapper is missing` and the screen flickers in a loop.**
  - `usb-moded.service.d/90-halium-limit.conf` – start-rate limit for usb-moded.
  - `halium-audio-route`, `halium-audio-prio`, `halium-wlan-up`, `halium-wifi-single-sta` services and `overlay/userdata/*.sh` – speaker route, PulseAudio thread priority, Wi-Fi fixes; `home-phablet/.config/systemd/user/halium-alsa-sink.service` – the ALSA sink.
  - `a50-gnss-init.service` sets the vendor boot-animation completion property inside Halium, restores the vendor GNSS device permissions and waits for the Samsung GNSS HAL. Copy `overlay/userdata/a50-overlays/a50-gnss-init` to `/userdata/a50-overlays/a50-gnss-init` with mode 0755 and preserve the unit's enablement symlink.
  - `a50-proximity.service` reads the STK3031 through sysfs on demand and exposes proximity events to sensorfwd for repowerd. Install the two service drop-ins and copy the matching script and configuration from `overlay/userdata/a50-overlays/` to `/userdata/a50-overlays/`.
  - `halium-speaker-fallback` (user service + `overlay/userdata/halium-speaker-fallback.sh`) – sends audio back to the speaker when a Bluetooth sink disappears; `99-a50-bluez-uhid.rules`, `etc/ofono/*`, `ofono.service.d`, `bluebinder.service.d` – Bluetooth/oFono wiring.
  - `halium-sshd.service` – debug sshd (key-only, add your own key to `/etc/ssh/halium_authorized_keys`).
  - `halium-livelog.service`, `halium-memwatch.service` (+ `overlay/userdata/halium-memwatch.sh`) – debug only: live logs and slab/memory watcher in `/userdata/live`.
- `overlay/notch/` – Lomiri QML patches (Panel, PanelMenu, PanelBar, Shell) for the notch and rounded corners, installed by bind mounts (`halium-notch.service`).

## Not included (on purpose)

- Partition backups, Samsung firmware, vendor/system images, rootfs/GSI images, logs. Extract
  `calliope_{sram,dram,iva}.bin` and `Tfa9872.cnt` from your own stock vendor image and put them in
  `kernel/mint/firmware/` before building (the Mint firmware Makefile only looks in that directory).
- The kernel tree itself: clone the upstream repository at the commit above and apply the patch.

## Build (short)

```bash
git clone --depth 1 -b android-14.0 https://github.com/FreshROMs/android_kernel_samsung_exynos9610_mint kernel/mint
git -C kernel/mint submodule update --init --depth 1
git -C kernel/mint apply ../patches/0001-halium-a50.patch   # from this repo's kernel/patches
tools/build-kernel.sh && tools/build-boot.sh
```

Requires clang, ld.lld and aarch64 binutils. Back up `boot` (and everything else) before flashing; flash only from TWRP.
Do not use a forced key-combo power cycle while the cable is connected for diagnostics: Samsung then boots in LPM/charger mode and overwrites `last_kmsg`.
