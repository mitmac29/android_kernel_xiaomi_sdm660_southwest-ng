#!/bin/bash
set -e

START=$(date +%s)

ZIPNAME="SW-lavender-4.19-$(date +%Y%m%d-%H%M).zip"

export KBUILD_BUILD_USER="Mitesh"
export KBUILD_BUILD_HOST="GitHub-Actions"

export LLVM=1
export LLVM_IAS=1

TC_DIR="$GITHUB_WORKSPACE/tc/zyc_clang"
IMAGE="out/arch/arm64/boot/Image.gz-dtb"

export PATH="$TC_DIR/bin:$PATH"

echo "================================="
echo "Kernel Version : $(make kernelversion)"
echo "Compiler       : $(clang --version | head -n1)"
echo "Branch         : $(git rev-parse --abbrev-ref HEAD)"
echo "Latest Commit  : $(git log --oneline -1)"
echo "================================="

rm -rf out
mkdir -p out

echo "Generating kernel config..."

make ARCH=arm64 O=out vendor/xiaomi/sdm660_defconfig

scripts/kconfig/merge_config.sh \
    -m \
    -O out \
    arch/arm64/configs/vendor/xiaomi/sdm660_defconfig \
    arch/arm64/configs/vendor/xiaomi/lavender.config

make ARCH=arm64 O=out olddefconfig

echo "Starting compilation..."

make -j$(nproc) \
    ARCH=arm64 \
    O=out \
    CC=clang \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    CLANG_TRIPLE=aarch64-linux-gnu-

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Kernel image not found!"
    echo "Contents of boot directory:"
    find out/arch/arm64/boot -type f 2>/dev/null || true
    exit 1
fi

echo "Cloning AnyKernel3..."

git clone --depth=1 \
    -b 4.19 \
    https://github.com/Sa-Sajjad/AnyKernel3 \
    AnyKernel3

cp "$IMAGE" AnyKernel3/

cd AnyKernel3

zip -r9 "../$ZIPNAME" *

cd ..

mkdir -p release
mv "$ZIPNAME" release/

END=$(date +%s)
DIFF=$((END - START))

echo ""
echo "================================="
echo "Build completed successfully!"
echo "ZIP : release/$ZIPNAME"
echo "Time: $((DIFF / 60))m $((DIFF % 60))s"
echo "================================="
