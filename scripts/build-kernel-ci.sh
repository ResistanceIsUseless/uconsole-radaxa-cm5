#!/bin/bash
#
# Build kernel for CI (assumes kernel and overlays already cloned)
#
# Usage: Called by GitHub Actions workflow
#
# Environment variables (must be set):
#   ARCH: Target architecture
#   CROSS_COMPILE: Cross-compiler prefix
#   KERNEL_VERSION: Kernel version suffix

set -e
set -u

KERNEL_DIR="build/kernel"
OVERLAYS_DIR="build/overlays"
OUTPUT_DIR="build/output"

echo "Building kernel..."
cd "${KERNEL_DIR}"
make rockchip_linux_defconfig
make -j$(nproc) Image modules dtbs

echo "Building kernel packages..."
export KDEB_PKGVERSION="${KERNEL_VERSION}"
make -j$(nproc) bindeb-pkg

echo "Collecting kernel packages..."
mkdir -p "../../${OUTPUT_DIR}/kernel-packages"
mv ../*.deb "../../${OUTPUT_DIR}/kernel-packages/"

echo "Building device tree overlays..."
cd "../../${OVERLAYS_DIR}"
mkdir -p compiled_overlays
mkdir -p "../output/overlays"

if [ -d "devicetree_overlays" ]; then
    KERNEL_INCLUDE="../../${KERNEL_DIR}/include"

    for dts in devicetree_overlays/*.dts; do
        [ -f "$dts" ] || continue
        basename=$(basename "$dts" .dts)
        echo "  Compiling: ${basename}"

        gcc -E -nostdinc -I"${KERNEL_INCLUDE}" -I"devicetree_overlays" \
            -undef -D__DTS__ -x assembler-with-cpp "$dts" | \
            dtc -@ -I dts -O dtb -o "compiled_overlays/${basename}.dtbo" -
    done

    cp compiled_overlays/*.dtbo "../output/overlays/"
fi

echo "Kernel build complete!"
