#!/bin/bash
# Package the locally built kernel and the upstream Halium ARM64 initramfs.
set -euo pipefail
cd "$(dirname "$0")/.."
source device/deviceinfo

kernel="kernel/out/arch/arm64/boot/$deviceinfo_kernel_image_name"
ramdisk=halium/halium-boot-ramdisk.img
mkbootimg=halium/android_system_tools_mkbootimg/mkbootimg.py
output=runs/boot.img

test -s "$kernel"
test -s "$ramdisk"
gzip -t "$ramdisk"
tmp=$(mktemp "${output}.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

python3 "$mkbootimg" --header_version "$deviceinfo_bootimg_header_version" \
  --os_version "$deviceinfo_bootimg_os_version" --os_patch_level "$deviceinfo_bootimg_os_patch_level" \
  --kernel "$kernel" --ramdisk "$ramdisk" --cmdline "$deviceinfo_kernel_cmdline" \
  --board "$deviceinfo_bootimg_board" --pagesize "$deviceinfo_flash_pagesize" \
  --base "$deviceinfo_flash_offset_base" --kernel_offset "$deviceinfo_flash_offset_kernel" \
  --ramdisk_offset "$deviceinfo_flash_offset_ramdisk" --second_offset "$deviceinfo_flash_offset_second" \
  --tags_offset "$deviceinfo_flash_offset_tags" -o "$tmp"

if [ "$deviceinfo_bootimg_tailtype" = SEAndroid ]; then
  printf 'SEANDROIDENFORCE' >> "$tmp"
fi

partition_backup=backups/device-2026-11-11/boot.img
if [ "$(stat -c %s "$tmp")" -gt "$(stat -c %s "$partition_backup")" ]; then
  echo "Boot image exceeds the backed-up boot partition size" >&2
  exit 1
fi

chmod 644 "$tmp"
mv -- "$tmp" "$output"
sha256sum "$output" > "$output.sha256"
