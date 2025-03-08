#!/bin/bash
# crave run --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/script.sh | bash"

# ======= USER CONFIGURATION =======
manifest_url="https://github.com/PixelOS-AOSP/manifest.git" # The rom you wanna build
manifest_branch="fifteen" # The branch

device_codename="phoenix"  # Example: miatoll, phoenix, surya
lunch_prefix="aosp"  # Example: aosp, lineage
device_soc="sm6150" # Example: sm6150

# Define build command
build_code="mka bacon -j$(nproc)" 

# ======= USER-DEFINED DIRECTORY STRUCTURE =======
# adapt accordingly to your tree
DT_DIR="device/xiaomi/${device_codename}" 
CDT_DIR="device/xiaomi/${device_soc}-common"
KERNEL_DIR="kernel/xiaomi/${device_soc}"
VENDOR_DIR="vendor/xiaomi/${device_codename}"
COMMON_VENDOR_DIR="vendor/xiaomi/${device_soc}-common"
HARDWARE_XIAOMI_DIR="hardware/xiaomi"
MIUICAMERA_DIR="vendor/xiaomi/miuicamera"

# ======= Define Trees and Branches Here =======
repos=(
    "$DT_DIR https://github.com/tillua467/phoenix-dt pos-15"
    "$CDT_DIR https://github.com/tillua467/sm6150-common pos-15"
    "$KERNEL_DIR https://github.com/Rom-Build-sys/android_kernel_xiaomi_sm6150 main"
    "$VENDOR_DIR https://github.com/tillua467/proprietary_vendor_xiaomi_phoenix main"
    "$COMMON_VENDOR_DIR https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common main"
    "$HARDWARE_XIAOMI_DIR https://github.com/tillua467/android_hardware_xiaomi lineage-22.1"
    "$MIUICAMERA_DIR https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera main"
)
# ======= CLEANUP =======
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="

#add you dir that you wannna remove here
dirs_to_remove=(
    "$DT_DIR"
    "$CDT_DIR"
    "$KERNEL_DIR"
    "$VENDOR_DIR"
    "$COMMON_VENDOR_DIR"
    "$HARDWARE_XIAOMI_DIR"
    "$MIUICAMERA_DIR"
    "out/target/product/*/*zip"
    "out/target/product/*/*txt"
    "out/target/product/*/boot.img"
    "out/target/product/*/recovery.img"
    "out/target/product/*/super*img"

)

for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && echo "Removed: $dir" || echo "Failed to remove: $dir"
    fi
done

echo "===================================="
echo "  Removing Unnecessary Files Done"
echo "===================================="

# ======= VERIFY DIRECTORIES REMOVED =======
echo "===================================="
echo " Verifying directory removal"
echo "===================================="

for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        echo "Warning: $dir still exists!"
    else
        echo "$dir successfully removed."
    fi
done

echo "===================================="
echo "   Directory verification done"
echo "===================================="


# ======= INIT & SYNC =======
echo "=============================================="
echo "         Cloning Manifest..........."
echo "=============================================="
if ! repo init -u "$manifest_url" -b "$manifest_branch" --git-lfs; then
  echo "Repo initialization failed. Exiting."
  exit 1
fi
echo "=============================================="
echo "       Manifest Cloned successfully"
echo "=============================================="

# Sync repo
if ! /opt/crave/resync.sh || ! repo sync -j$(nproc) --force-sync; then
  echo "Repo sync failed. Exiting."
  exit 1
fi
echo "============="
echo " Sync success"
echo "============="

# ======= CLONE DEVICE TREES =======
echo "=============================================="
echo "       Cloning Trees..........."
echo "=============================================="
for entry in "${repos[@]}"; do
    repo_path=$(echo "$entry" | awk '{print $1}')
    repo_url=$(echo "$entry" | awk '{print $2}')
    repo_branch=$(echo "$entry" | awk '{print $3}')
    
    echo "Cloning $repo_url -> $repo_path ($repo_branch)"
    git clone -b "$repo_branch" "$repo_url" "$repo_path" || { echo "Failed to clone $repo_url"; exit 1; }
done

/opt/crave/resync.sh # sync the trees now

# Any extra stuff
rm -rf hardware/xiaomi/megvii

# ======= EXPORT ENVIRONMENT VARIABLES =======
echo "======= Exporting........ ======"
export BUILD_USERNAME=tillua467
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# ======= BUILD ENVIRONMENT =======
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="

# Try lunch first
LUNCH_OPTIONS=(
    "lunch ${lunch_prefix}_${device_codename}-ap4a-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-ap3a-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-ap2a-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-userdebug"
)

success=false
for CMD in "${LUNCH_OPTIONS[@]}"; do
    echo "Trying: $CMD"
    if eval "$CMD"; then
        success=true
        break
    fi
done

# If all lunch commands fail, try breakfast
if [ "$success" = false ]; then
    echo "All lunch commands failed, trying: breakfast ${device_codename}"
    breakfast ${lunch_prefix}_${device_codename}-userdebug || { echo "Breakfast failed. Exiting."; exit 1; }
fi

# ======= BUILD THE ROM =======
if [ $? -eq 0 ]; then
    echo "Lunch/Breakfast successful, running build command: $build_code"
    eval "$build_code"
else
    echo "All attempts failed, exiting."
    exit 1
fi
