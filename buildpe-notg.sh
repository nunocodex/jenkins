#!/bin/bash
echo "Current CPUs: $(nproc --all)"
echo "Current ram: $(free -h)"
mkdir ~/android
cd ~/android
mkdir pixel
cd pixel
repo init -u https://github.com/PixelExperience/manifest -b ten
cd ~/android/pixel && repo sync --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
if [ $? -eq 0 ]; then
else
exit 1
fi
echo "Removing old builds zip files..."
cd ~/android/pixel
rm -rf out/target/product/lavender/PixelExperience_lavender-10.0-*
echo "Done!"
echo "Initializing build..."
source build/envsetup.sh
breakfast lavender
brunch lavender
if [ $? -eq 0 ]; then
    echo "Build completed succesfully! Uploading to /pixel/ folder..."
    scp  out/target/product/lavender/PixelExperience*-UNOFFICIAL.zip daniml3@frs.sourceforge.net:/home/frs/project/lavenderbuilds/pixel/
    bash ~/android/jenkins/gen_mirror_json.sh
    cd  ~/android/ota/ && git add . && git commit -m "Update" && git push
else
    echo "Build failed, exiting..."
fi
