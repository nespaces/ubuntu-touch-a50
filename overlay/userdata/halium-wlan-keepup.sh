#!/bin/sh
# SCSC wlan0 gets closed ~11 s after boot and then stays DOWN: keep it up while Wi-Fi is enabled
while true; do
  if [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ] && ip link show wlan0 >/dev/null 2>&1; then
    ip link show wlan0 | head -1 | grep -q "<[^>]*UP" || ip link set wlan0 up 2>/dev/null
  fi
  sleep 3
done
