#!/bin/bash
# crave run --no-patch -- "curl https://raw.githubusercontent.com/Zekerian/Android-Scripts/refs/heads/test/Infinity.sh | bash"

# ======= USER CONFIGURATION =======
manifest_url="https://github.com/ProjectInfinity-X/manifest.git" # The rom you wanna build
manifest_branch="15" # The branch

device_codename="miami"  # Example: miatoll, phoenix, surya
lunch_prefix="infinity"        # Example: aosp, lineage
device_soc="sm6375"        # Example: sm6375

# Define build command
build_code="mka bacon -j$(nproc)"

# ======= USER-DEFINED DIRECTORY STRUCTURE =======
DT_DIR="device/motorola/${device_codename}"
CDT_DIR="device/motorola/${device_soc}-common"
KERNEL_DIR="kernel/motorola/${device_soc}"
VENDOR_DIR="vendor/motorola/${device_codename}"
COMMON_VENDOR_DIR="vendor/motorola/${device_soc}-common"
HARDWARE_MOTOROLA_DIR="hardware/motorola"
PREBUILTS_CLANG_DIR="prebuilts/clang/host/linux-x86/clang-rastamod"

# ======= Define Trees and Branches Here =======
repos=(
    "$DT_DIR https://github.com/Zekerian/android_device_motorola_miami InfinityX"
    "$CDT_DIR https://github.com/Zekerian/android_device_motorola_sm6375-common InfinityX"
    "$KERNEL_DIR https://github.com/Motorola-Miami/android_kernel_motorola_sm6375 15.0-KSU"
    "$VENDOR_DIR https://gitlab.com/Motorola-Miami/proprietary_vendor_motorola_miami 15.0-test"
    "$COMMON_VENDOR_DIR https://github.com/Motorola-Miami/proprietary_vendor_motorola_sm6375-common 15.0-test"
    "$HARDWARE_MOTOROLA_DIR https://github.com/Motorola-Miami/android_hardware_motorola 15.0"
    "$PREBUILTS_CLANG_DIR https://gitlab.com/kutemeikito/rastamod69-clang clang-20.0"
)

# ======= DEPENDENCY CHECK =======
echo "Checking required tools..."
for cmd in repo git bash rm curl; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: '$cmd' is missing. Install it before running the script."
        exit 1
    fi
done

# ======= CLEANUP =======
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="

dirs_to_remove=(
    "$DT_DIR"
    "$CDT_DIR"
    "$KERNEL_DIR"
    "$VENDOR_DIR"
    "$COMMON_VENDOR_DIR"
    "$HARDWARE_MOTOROLA_DIR"
    "$PREBUILTS_CLANG_DIR"
)

files_to_remove=(
    "out/target/product/${device_codename}/*.zip"
    "out/target/product/${device_codename}/*.txt"
    "out/target/product/${device_codename}/boot.img"
    "out/target/product/${device_codename}/recovery.img"
    "out/target/product/${device_codename}/super*img"
)

for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && echo "Removed directory: $dir"
    fi
done

for file in "${files_to_remove[@]}"; do
    rm -f $file && echo "Removed file(s): $file"
done

echo "===================================="
echo "  Cleanup Done"
echo "===================================="

# ======= INIT & SYNC =======
echo "=============================================="
echo "         Cloning Manifest..."
echo "=============================================="
if ! repo init -u "$manifest_url" -b "$manifest_branch" --git-lfs; then
    echo "Repo initialization failed. Exiting."
    exit 1
fi

echo "Manifest cloned successfully."

if ! /opt/crave/resync.sh || ! repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all); then
  echo "Repo sync failed. Exiting."
  exit 1
fi

echo "=============================================="
echo "         Sync Success"
echo "=============================================="

# ======= CLONE DEVICE TREES =======
echo "=============================================="
echo "       Cloning Trees..."
echo "=============================================="

for entry in "${repos[@]}"; do
    repo_path=$(echo "$entry" | awk '{print $1}')
    repo_url=$(echo "$entry" | awk '{print $2}')
    repo_branch=$(echo "$entry" | awk '{print $3}')

    echo "Cloning $repo_url -> $repo_path ($repo_branch)"
    git clone -b "$repo_branch" "$repo_url" "$repo_path" || { echo "Failed to clone $repo_url"; exit 1; }
done

/opt/crave/resync.sh # sync the trees

# ======= EXPORT ENVIRONMENT VARIABLES =======
echo "======= Exporting Environment Variables ======"
export BUILD_USERNAME=zeke
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# ======= BUILD ENVIRONMENT =======
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="

# ======= SELECT BUILD TARGET =======
LUNCH_OPTIONS=(
    "lunch ${lunch_prefix}_${device_codename}-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-ap4a-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-ap3a-userdebug"
    "lunch ${lunch_prefix}_${device_codename}-ap2a-userdebug"
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
    echo "All lunch commands failed, trying: breakfast ${lunch_prefix}_${device_codename}-userdebug"
    breakfast ${lunch_prefix}_${device_codename}-userdebug || { echo "Breakfast failed. Exiting."; exit 1; }
    success=true
fi

# ======= BUILD THE ROM =======
if [ "$success" = true ]; then
    echo "Lunch/Breakfast successful, running build command: $build_code"
    $build_code
    BUILD_STATUS=$?
    if [ $BUILD_STATUS -eq 0 ]; then
        echo "Build completed successfully!"
    else
        echo "Build failed! Fetching error.log..."
        find out/target/product/${device_codename} -name "error.log" -exec cat {} \;
        exit 1
    fi
else
    echo "All attempts to select a build target failed, exiting."
    exit 1
fi

# ======= UPLOAD TO GOFILE.IO (only if build succeeded) =======
echo "=============================================="
echo "      Searching for the built ROM..."
echo "=============================================="

ROM_FILE=$(find out/target/product/${device_codename} -name "*.zip" -type f | sort -r | head -n 1)

if [[ -z "$ROM_FILE" ]]; then
    echo "Error: No ROM zip file found in out/target/product/${device_codename}"
    exit 1
fi

echo "Found ROM: $ROM_FILE"

echo "=============================================="
echo "     Uploading ROM to Gofile.io..."
echo "=============================================="

UPLOAD_RESPONSE=$(curl -s -F "file=@$ROM_FILE" "https://store7.gofile.io/uploadFile")
DOWNLOAD_LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"downloadPage":"[^"]*' | cut -d '"' -f4)

if [[ -n "$DOWNLOAD_LINK" ]]; then
    echo "=============================================="
    echo "        Upload Successful!"
    echo "Download Link: $DOWNLOAD_LINK"
    echo "=============================================="
else
    echo "Error: Upload failed!"
    exit 1
fi
