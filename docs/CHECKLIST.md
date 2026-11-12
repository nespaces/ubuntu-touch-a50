# Feature checklist (Galaxy A50, Halium 11 / Ubuntu Touch 20.04)

Same categories as the [UBports device pages](https://devices.ubuntu-touch.io/). Only things that were actually
tried on a clean install of the release ZIP are marked as working.

✅ works · ⚠️ works with limits · ❔ not tested · ❌ does not work

## Actors
- ✅ Manual brightness
- ❔ Torchlight
- ⚠️ Vibration — the motor works (`hfd-service` drives `timed_output`), but the 10 ms keyboard pulse is hardly noticeable

## Camera
- ❔ Flashlight
- ✅ Photo
- ❔ Video
- ❔ Switching between cameras

## Cellular
- ❔ Carrier info, signal strength
- ❔ Data connection
- ❔ Dual SIM functionality
- ❔ Incoming / outgoing calls
- ❔ MMS in / out
- ❔ PIN unlock
- ❔ SMS in / out
- ❔ Change audio routings
- ❔ Voice in calls
- ❔ Volume control in calls

oFono is bound to the Android IRadio 1.4 HAL (both slots powered and online). It has not been verified with a SIM card yet.

## Endurance
- ❔ 24+ hours battery lifetime
- ❔ 7+ days stability

## GPU
- ✅ Boot into UI
- ❔ Hardware video playback

## Misc
- ❔ Waydroid
- ✅ AppArmor patches (AppArmor is the major LSM, `SO_PEERSEC` hook in the kernel)
- ✅ Battery percentage
- ❔ Offline charging
- ✅ Online charging
- ✅ Recovery image (stock TWRP)
- ❔ Reset to factory defaults
- ❔ RTC time
- ✅ SD card storage (shown next to internal storage over MTP)
- ✅ Shutdown / Reboot
- ❔ Wireless charging
- ❌ Wireless external monitor

## Network
- ✅ Bluetooth (AirPods Pro A2DP and a mouse verified)
- ❔ Flight mode
- ❔ Hotspot
- ⚠️ NFC — tags are detected by `nfcd`; NDEF read/write is untested
- ✅ Wi-Fi (single STA: `wlan0`; a second STA interface crashes the SCSC firmware)

## Sensors
- ❔ Automatic brightness
- ❌ Fingerprint reader — `biometryd` is masked, it aborts on every client query and takes the Security settings page down with it
- ✅ GPS
- ✅ Proximity
- ✅ Rotation
- ✅ Touchscreen

## Sound
- ❔ Earphones
- ✅ Loudspeaker
- ❔ Microphone
- ✅ Volume control (hardware keys and system sounds)

## USB
- ✅ MTP access
- ❔ ADB access (developer mode gives RNDIS + ssh)

## Display extras
- ✅ Notch / rounded-corner layout in portrait and landscape (Lomiri QML overlay)
