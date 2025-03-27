#!/bin/bash
# crave run --no-patch -- "curl https://raw.githubusercontent.com/Zekerian/Android-Scripts/refs/heads/InfinityX/LOSP.sh | bash"

# Remove Unnecessary Files
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="

dirs_to_remove=(
  "vendor/motorola"
  "kernel/motorola"
  "device/motorola"
  "device/motorola/sm6375-common"
  "vendor/motorola/sm6375-common"
  "hardware/motorola"
  "prebuilts/clang/host/linux-x86/clang-rastamod"
  "out/target/product/*/*zip"
  "out/target/product/*/*txt"
  "out/target/product/*/boot.img"
  "out/target/product/*/recovery.img"
  "out/target/product/*/super*img"
  ".repo/local_manifests/"
)

for dir in "${dirs_to_remove[@]}"; do
  [ -e "$dir" ] && rm -rf "$dir"
done

echo "===================================="
echo "  Removing Unnecessary Files Done"
echo "===================================="

# Initialize repo
echo "=============================================="
echo "         Cloning Manifest..........."
echo "=============================================="
if ! repo init --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 15 -g default,-mips,-darwin,-notdefault; then
  echo "Repo initialization failed. Exiting."
  exit 1
fi
echo "=============================================="
echo "       Manifest Cloned successfully"
echo "=============================================="
# Sync
if ! /opt/crave/resync.sh || ! repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all); then
  echo "Repo sync failed. Exiting."
  exit 1
fi
echo "============="
echo " Sync success"
echo "============="

# Clone device trees and other dependencies
echo "=============================================="
echo "       Cloning Trees..........."
echo "=============================================="
git clone https://github.com/Zekerian/android_device_motorola_miami -b InfinityX device/motorola/miami || { echo "Failed to clone device tree"; exit 1; }

git clone https://github.com/Zekerian/android_device_motorola_sm6375-common -b InfinityX device/motorola/sm6375-common || { echo "Failed to clone common device tree"; exit 1; }

git clone https://github.com/Motorola-Miami/android_kernel_motorola_sm6375 -b 15.0-KSU kernel/motorola/sm6375 || { echo "Failed to clone kernel"; exit 1; }

git clone https://gitlab.com/Motorola-Miami/proprietary_vendor_motorola_miami -b 15.0-test vendor/motorola/miami || { echo "Failed to clone vendor miami"; exit 1; }

git clone https://github.com/Motorola-Miami/proprietary_vendor_motorola_sm6375-common -b 15.0-test vendor/motorola/sm6375-common || { echo "Failed to clone common vendor miami"; exit 1; }

git clone https://github.com/Motorola-Miami/android_hardware_motorola hardware/motorola || { echo "Failed to clone hardware"; exit 1; }

git clone https://gitlab.com/kutemeikito/rastamod69-clang prebuilts/clang/host/linux-x86/clang-rastamod || { echo "Failed to clone prebuilts clang-rastamod"; exit 1; }

# croot && git clone https://github.com/ProjectInfinity-X/vendor_infinity-priv_keys-template vendor/infinity-priv/keys || { echo "Failed to sign"; exit 1;}

# cd vendor/infinity-priv/keys && chmod +x keys.sh

# ./keys.sh && cd ../../../

/opt/crave/resync.sh

# Export Environment Variables
echo "======= Exporting........ ======"
export BUILD_USERNAME=Zeke
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# Set up build environment
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="


# Build ROM
echo "===================================="
echo "        Build Infinity.."
echo "===================================="
lunch infinity_miami-eng
mka bacon
