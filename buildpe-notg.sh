#!/bin/bash
echo "Current CPUs: $(nproc --all)"
echo "Current ram: $(free -h)"
echo "Current DISK: $(df -h)"
mkdir ~/android
cd ~/android
mkdir pixel
cd  ~/android/pixel
repo init -u https://github.com/PixelExperience/manifest -b ten
repo sync --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
git clone https://github.com/daniml3/ota ~/android/ota
if [ $? -eq 0 ]; then
echo "Success"
else
exit 1
fi
cd ~/android/pixel
rm -rf packages/apps/Settings
git clone https://github.com/daniml3/android_packages_apps_settings packages/apps/settings -b 10
rm -rf packages/apps/Updates
git clone https://github.com/daniml3/android_packages_apps_updates packages/apps/Updates -b 10
git clone https://github.com/daniml3/android_device_xiaomi_lavender device/xiaomi/lavender
git clone https://github.com/daniml3/android_vendor_xiaomi_lavender vendor/xiaomi/lavender 
git clone https://github.com/LineageOS/android_packages_resources_devicesettings packages/resources/devicesettings -b lineage-17.0
git clone https://github.com/faham1997/kernel kernel/xiaomi/lavender
echo "Initializing build..."
source build/envsetup.sh
breakfast lavender
brunch lavender
if [ $? -eq 0 ]; then
    echo "Build completed succesfully! Uploading to /pixel/ folder..."
    scp  out/target/product/lavender/PixelExperience*-UNOFFICIAL.zip daniml3@frs.sourceforge.net:/home/frs/project/lavenderbuilds/pixel/
    bash ~/android/ota/gen_mirror_json.sh
    cd  ~/android/ota/ && git add . && git commit -m "Update" && git push
else
    echo "Build failed, exiting..."
fi
