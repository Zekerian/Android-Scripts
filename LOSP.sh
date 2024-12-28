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
rm -rf  vendor/xiaomi
rm -rf  kernel/xiaomi
rm -rf  device/xiaomi
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
echo "       Cloning Mniafest..........."
echo "=============================================="
repo init --depth=1 --no-repo-verify -u https://github.com/yehonatan2020/losp_manifest -b lineage-22.1 --git-lfs
echo "=============================================="
echo "       Mniafest Cloned successfully"
echo "=============================================="

echo "=================================="
echo "Cloning Necessary trees............"
echo "=================================="
# DT
git clone https://github.com/tillua467/phoenix-dt -b LOS-22 device/xiaomi/phoenix
# CDT
git clone https://github.com/tillua467/sm6150-common -b a15 device/xiaomi/sm6150-common
# KT 
git clone https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150 -b lineage-22.1 kernel/xiaomi/sm6150
# VT
git clone https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_phoenix -b a15 vendor/xiaomi/phoenix
# CVT 
git clone https://github.com/tillua467/vendor_sm6150-common -b a15 vendor/xiaomi/sm6150-common
# HT
git clone 
# MIUI CAM
git clone https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera -b fifteen-leica vendor/xiaomi/miuicamera
#Viper FX
