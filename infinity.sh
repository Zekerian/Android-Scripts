#!/bin/bash

# Upgrade System
sudo apt update && sudo apt upgrade -y
echo "========================================================================"
echo "                        SYSTEM UPGRADED"
echo "========================================================================="

# Remove Unnecessary Files
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="
rm -rf .repo/local_manifests
rm -rf vendor/xiaomi
rm -rf kernel/xiaomi
rm -rf device/xiaomi
rm -rf device/xiaomi/sm6150-common
rm -rf vendor/xiaomi/sm6150-common
rm -rf hardware/xiaomi
rm -rf out/target/product/*/*zip
rm -rf out/target/product/*/*txt
rm -rf out/target/product/*/boot.img
rm -rf out/target/product/*/recovery.img
rm -rf out/target/product/*/super*img

echo "===================================="
echo "  Removing Unnecessary Files Done"
echo "===================================="

# repo init rom
echo "=============================================="
echo "       Cloning Manifest..........."
echo "=============================================="
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 15 -g default,-mips,-darwin,-notdefault
echo "=============================================="
echo "       Mniafest Cloned successfully"
echo "=============================================="

# Sync
/opt/crave/resync.sh && repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
echo "============="
echo " Sync success"
echo "============="

echo "=============================================="
echo "       Cloning Tress..........."
echo "=============================================="

git clone https://github.com/tillua467/phoenix-dt.git device/xiaomi/phoenix
git clone https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150 kernel/xiaomi/sm6150
git clone https://github.com/tillua467/sm6150-common.git device/xiaomi/sm6150-common
git clone https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_phoenix.git vendor/xiaomi/phoenix
git clone https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common.git vendor/xiaomi/sm6150-common
git clone https://github.com/rom-vayu/android_hardware_xiaomi.git hardware/xiaomi
git clone https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera vendor/xiaomi/miuicamera
/opt/crave/resync.sh

# Export
echo "======= Exporting........ ======"
export BUILD_USERNAME=tillua467 
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# Set up build environment
echo "====== Starting Envsetup ======="
source build/envsetup.sh
echo "====== Envsetup Done ======="

# Lunch
echo "======Lunching....========"
lunch infinity_phoenix-userdebug
echo "=====Lunching done========"

# Make cleaninstall
make installclean
echo "============="

# Build rom
echo "===================================="
echo "        Build Infinty-X..."
echo "===================================="
mka bacon

