#!/bin/bash
# Build Mint for Halium in kernel/out.
set -e
cd "$(dirname "$0")/../kernel/mint"
source_dir=$(pwd)
output_dir=$(realpath ../out)
mkdir -p "$output_dir"

export ANDROID_MAJOR_VERSION=r

# Keep Clang 21 diagnostics visible without stopping the legacy kernel build.
warning_flags="-Wno-error=unused-but-set-variable -Wno-error=default-const-init-field-unsafe"
warning_flags+=" -Wno-error=default-const-init-var-unsafe -Wno-error=implicit-enum-enum-cast"
warning_flags+=" -Wno-error=frame-larger-than"

# Resolve .incbin firmware paths from the source tree in out-of-tree builds.
make_args=(
  "O=$output_dir" ARCH=arm64 CC=clang HOSTCC=clang HOSTLD=ld.lld
  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu-
  "KCFLAGS=$warning_flags" "KAFLAGS=-Wa,-I,$source_dir"
)

if [ ! -f "$output_dir/.config" ]; then
  make "${make_args[@]}" exynos9610-a50_core_defconfig
  scripts/kconfig/merge_config.sh -m -O "$output_dir" "$output_dir/.config" ../halium.fragment
fi

make "${make_args[@]}" olddefconfig
make "${make_args[@]}" -j"$(nproc)" Image dtbs
