. build/envsetup.sh
# Lunch
lunch lineage_phoenix-ap3a-userdebug || lunch lineage_phoenix-ap2a-userdebug
echo =============

# Make cleaninstall
axion phoenix userdebug
axion phoenix gms pico
brunch phoenix
