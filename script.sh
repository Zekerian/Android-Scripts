#!/bin/bash
# crave run --clean --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/script.sh | bash"

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
if ! repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs; then
  echo "Repo initialization failed. Exiting."
  exit 1
fi
echo "=============================================="
echo "       Manifest Cloned successfully"
echo "=============================================="

# Sync
if ! /opt/crave/resync.sh || ! repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags; then
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
git clone https://github.com/tillua467/phoenix-dt.git device/xiaomi/phoenix || { echo "Failed to clone device tree"; exit 1; }
git clone https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150 kernel/xiaomi/sm6150 || { echo "Failed to clone kernel"; exit 1; }
git clone https://github.com/tillua467/sm6150-common.git device/xiaomi/sm6150-common || { echo "Failed to clone sm6150-common"; exit 1; }
git clone https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_phoenix.git vendor/xiaomi/phoenix || { echo "Failed to clone vendor phoenix"; exit 1; }
git clone https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common.git vendor/xiaomi/sm6150-common || { echo "Failed to clone sm6150-common vendor"; exit 1; }
git clone https://github.com/rom-vayu/android_hardware_xiaomi.git hardware/xiaomi || { echo "Failed to clone hardware"; exit 1; }
git clone https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera vendor/xiaomi/miuicamera || { echo "Failed to clone MIUI Camera"; exit 1; }
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

# Lunch
echo "====== Lunching.... ========"
lunch lineage_phoenix-ap4a-userdebug || { echo "Lunch command failed"; exit 1; }
echo "===== Lunching done ========"

# Clean install
make installclean || { echo "Installclean failed"; exit 1; }
echo "============="

# Build ROM
echo "===================================="
echo "        Build Evo-X..."
echo "===================================="
m evolution || { echo "Build failed"; exit 1; }
