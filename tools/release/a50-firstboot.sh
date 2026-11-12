#!/bin/sh
# Galaxy A50 Ubuntu Touch: first-boot installer. Copies the A50 overlay from the read-only rootfs
# into the writable layer (/etc is persistent on /userdata/system-data) and reboots once.
SRC=/usr/share/a50-overlay
MARK=/userdata/.a50-installed-v1
H=/home/phablet
[ -e "$MARK" ] && exit 0

# wait for the persistent bind mounts to be there
for i in $(seq 1 60); do
  mountpoint -q /etc/systemd/system && mountpoint -q /etc/udev/rules.d && [ -d "$H" ] && [ -w "$H" ] && break
  sleep 2
done
mountpoint -q /etc/systemd/system || { echo "persistent /etc/systemd/system not ready"; exit 1; }

# cp -a on /etc/. tries to set times on read-only rootfs dirs and returns 1: copy tolerantly, then verify
cpt() { cp -a --no-preserve=timestamps "$@" || true; }
cpt "$SRC/system-data/etc/." /etc/
# systemd bind-mount units may have pre-created a DIRECTORY where we ship a FILE (e.g. a50-ofono-deviceinfo.yaml)
for f in "$SRC"/userdata/*; do
  b=$(basename "$f")
  if [ -f "$f" ] && [ -d "/userdata/$b" ]; then umount "/userdata/$b" 2>/dev/null || true; rm -rf "/userdata/$b"; fi
done
cpt "$SRC/userdata/." /userdata/
[ -e /etc/systemd/system/halium-notch.service ] && [ -e /userdata/a50-overlays/a50-proximity.py ] \
  && [ -f /userdata/a50-ofono-deviceinfo.yaml ] && [ -e /etc/default/usb-moded.d/10-halium-ids.conf ] || { echo "overlay copy incomplete"; exit 1; }
set -e
chmod 755 /userdata/halium-*.sh /userdata/a50-overlays/a50-gnss-init 2>/dev/null || true

# enable our units
install -d /etc/systemd/system/multi-user.target.wants
for u in halium-audio-prio halium-audio-route halium-notch halium-wifi-single-sta halium-wlan-up; do
  ln -sf /etc/systemd/system/$u.service /etc/systemd/system/multi-user.target.wants/$u.service
done

# a50-gnss-init is WantedBy=lomiri-location-service.service
install -d /etc/systemd/system/lomiri-location-service.service.wants
ln -sf /etc/systemd/system/a50-gnss-init.service /etc/systemd/system/lomiri-location-service.service.wants/a50-gnss-init.service

# biometryd asserts on every client query here (D-Bus AppArmor context unknown) and takes Settings -> Security down with it
ln -sf /dev/null /etc/systemd/system/biometryd.service

# user units and scripts for phablet
install -d -o phablet -g phablet "$H/.config" "$H/.config/systemd" "$H/.config/systemd/user" \
  "$H/.config/systemd/user/default.target.wants" "$H/.local" "$H/.local/bin"
cpt "$SRC/home-phablet-user-units/." "$H/.config/systemd/user/"
cpt "$SRC/home-phablet-bin/." "$H/.local/bin/"
ln -sf ../halium-alsa-sink.service "$H/.config/systemd/user/default.target.wants/halium-alsa-sink.service"
ln -sf ../halium-speaker-fallback.service "$H/.config/systemd/user/default.target.wants/halium-speaker-fallback.service"
chown -R phablet:phablet "$H/.config/systemd" "$H/.local"

touch "$MARK"
sync
echo "A50 overlay installed, rebooting once"
systemctl reboot
