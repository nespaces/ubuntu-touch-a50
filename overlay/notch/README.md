# Notch / rounded-corner layout for Lomiri 0.2.1 (Ubuntu 20.04) on the Galaxy A50

Lomiri in this image has no notch support. These patches (against the stock files in `/usr/share/lomiri`)
make the portrait status bar fit the "waterdrop" notch and the rounded display corners:

- clock in the far-left corner, drawn by `Shell.qml` above every layer (launcher, app drawer);
- indicators to the right of the notch, inset from the rounded right corner;
- the pull-down handle stays full width (left, centre and right all open the shade);
- the expanded indicator tab row is pushed below the camera cut-out (the row lives in a Flickable rotated by 180 degrees, so the inset is a `bottomMargin`).

Tunables in `Panel.qml`: `notchHalfWidth` (4 gu), `notchInset` (3 gu), corner margin (3.5 gu).  1 gu = 21 px here.

## Install without touching the rootfs

```sh
mkdir -p /userdata/a50-overlays
for f in Panel/Panel.qml Panel/PanelMenu.qml Panel/PanelBar.qml Shell.qml; do
  cp /usr/share/lomiri/$f /tmp/$(basename $f)
  patch -o /userdata/a50-overlays/$(basename $f) /tmp/$(basename $f) < $(basename $f).diff
done
```

then enable `halium-notch.service` (see `overlay/userdata-system-data/etc/systemd/system`), which bind-mounts the patched files before the
session starts. Roll back with `systemctl disable --now halium-notch.service`.
