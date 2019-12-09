#!/bin/bash
HOME=/home/daniel
cd $HOME
clean="no"
DATE=$(date +'%Y-%m-%d -- %H:%M')
MESSAGE="========================="
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
MESSAGE="$DATE : Started syncing the repo to build."
        curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
cd ~/android/pixel && repo sync --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
if [ $? -eq 0 ]; then
MESSAGE="Synced succesfully!"
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
else
MESSAGE="Failed to sync."
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
exit 1
fi
echo "Removing old builds zip files..."
cd ~/android/pixel
rm -rf out/target/product/lavender/PixelExperience_lavender-10.0-*
echo "Done!"
echo "Initializing build..."
	#Push telegram message
	MESSAGE="New build started!. Date: $DATE"
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
source build/envsetup.sh
breakfast lavender
brunch lavender
if [ $? -eq 0 ]; then
    echo "Build completed succesfully! Uploading to /pixel/ folder..."
    scp  out/target/product/lavender/PixelExperience*-UNOFFICIAL.zip daniml3@frs.sourceforge.net:/home/frs/project/lavenderbuilds/pixel/
    FILENAME=$(find out/target/product/lavender/PixelExperience*.zip | cut -d "/" -f 5)
    bash ~/android/jenkins/gen_mirror_json.sh
    cd  ~/android/ota/ && git add . && git commit -m "Update" && git push
	#Send new update message.
	MESSAGE="New update detected. Date: $DATE"
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
	UPDATE_URL1="https://sourceforge.net/projects/lavenderbuilds/files/pixel/$FILENAME"
	UPDATE_URL2="/download"
	UPDATE_URL=$UPDATE_URL1$UPDATE_URL2
	MESSAGE="Update url: $UPDATE_URL"
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
else
    echo "Build failed, exiting..."
	MESSAGE="Build of date $DATE failed."
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
fi
MESSAGE="========================="
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d chat_id=-1001496849074 -d text="$MESSAGE"
