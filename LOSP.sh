#!/bin/bash

# Update the System
sudo apt update && sudo apt upgrade -y
echo "========================================================================"
echo "                        SYSTEM UPGRADED"
echo "========================================================================="

# Remove Unnecessary Files
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="
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

# initialize the rom manifest 
echo "=============================================="
echo "       Cloning Manifest..........."
echo "=============================================="
repo init --depth=1 --no-repo-verify -u https://github.com/Lineage-OS-Special-Project/losp_manifests -b lineage-22.1 --git-lfs
echo "=============================================="
echo "       Manifest Cloned successfully"
echo "=============================================="

echo "=================================="
echo "Cloning Necessary trees............"
echo "=================================="
# CDT
git clone https://github.com/TheMuppets/proprietary_vendor_sony_kirin vendor/sony
# VT
git clone https://github.com/TheMuppets/proprietary_vendor_sony_nile-common vendor/sony
source build/envsetup.sh
lunch lineage_kirin-ap3a-userdebug
m bacon
