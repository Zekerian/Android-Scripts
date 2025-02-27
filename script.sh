#!/bin/bash
# crave run --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/script.sh | bash"

# Remove Unnecessary Files
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="

dirs_to_remove=(
  "vendor/xiaomi"
  "kernel/xiaomi"
  "device/xiaomi"
  "device/xiaomi/sm6150-common"
  "vendor/xiaomi/sm6150-common"
  "hardware/xiaomi"
  "out/target/product/*/*zip"
  "out/target/product/*/*txt"
  "out/target/product/*/boot.img"
  "out/target/product/*/recovery.img"
  "out/target/product/*/super*img"
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
if ! repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 15 -g default,-mips,-darwin,-notdefault; then
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

rm -rf hardware/xiaomi

# Clone device trees and other dependencies
# Local manifests
echo "=================================="
echo "Cloning Local manifest............"
echo "=================================="
repo init --no-repo-verify https://github.com/tillua467/local_manifests .repo/local_manifests
repo sync -c
echo "=================================="
echo "Local manifest cloned successfully"
echo "=================================="
/opt/crave/resync.sh

 # clone
rm -rf vendor/infinity
git clone https://github.com/Gtajisan/vendor_infinity -b 15 vendor/infinity
/opt/crave/resync.sh 

# Export Environment Variables
echo "======= Exporting........ ======"
export BUILD_USERNAME=tillua467
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
lunch infinity_phoenix-userdebug && mka bacon || lunch infinity_phoenix-ap3a-userdebug && mka bacon ||  lunch infinity_phoenix-ap4a-userdebug && mka bacon || { echo "Build failed"; exit 1; }

