# Release ZIP (TWRP) — how it is built

The ZIP contains `boot.img`, `rootfs.img.gz`, `android-rootfs.img.gz`, `checksums.sha256` and the installer
(`META-INF/com/google/android/update-binary`, plain shell). The installer checks the device and the stock Android 11 vendor
partition, flashes the boot image, writes both system images to `/data` and verifies the checksums.

1. **boot.img** — `tools/build-kernel.sh` + `tools/build-boot.sh` (kernel with the Samsung audio firmware built in), padded to the partition size (57671680 bytes).
2. **rootfs.img** — the UBports focal `rootfs.img` with the A50 overlay injected using `debugfs -w` (no root needed):
   - `/usr/share/a50-overlay/{system-data,userdata,home-phablet-*}` — the files from `overlay/` that must live on the writable layer;
   - `/usr/libexec/a50-firstboot.sh` + `a50-firstboot.service` — on the first boot it copies the overlay into `/etc`, `/userdata` and the
     phablet home, enables the A50 units, masks `biometryd`, writes `/userdata/.a50-installed-v1` and reboots once;
   - the read-only parts of the image itself: `usb-moded` IDs/mode, `touch.pa`, the Halium overlay `.rc` files, pulseaudio drop-in.
   Debug-only things (sshd, live logs, memwatch, helper tests) must **not** be in the image.
3. **android-rootfs.img** — the unmodified UBports Halium 11 GSI.
4. `python3 build-zip.py vX.Y.Z` writes `checksums.sha256` and the ZIP (images are stored, not deflated; GitHub's limit is 2 GB per asset).

Why a first-boot service: `/etc/systemd/system`, `/etc/udev/rules.d`, `/etc/default`... are bind-mounted from `/userdata/system-data`
and populated at the first boot, so files placed there before the first boot would be shadowed or break that population.
