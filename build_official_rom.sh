#!/bin/bash

TG_BOT_LOG_CHAT="-1001182833534"
TG_BOT_MAINTAINERS_CHAT="-1001197980605"
TG_BOT_NEWS_CHAT="@CleanDroidOS"

CUSTOM_BUILD_TYPE=OFFICIAL
CLEAN_BUILD_TYPE=$CUSTOM_BUILD_TYPE

REPO_DEVICE_BRANCH=$jk_device_branch
REPO_DEVICE_CODENAME=$jk_device_codename
REPO_MANIFEST_URL=$jk_manifest_url

BUILD_MAKE_CLEAN=$jk_make_clean
BUILD_OUTPUT_DIR="out/target/product/${BUILD_DEVICE_CODENAME}"

UPLOAD_PUSHWAIT=0

function TG_Logs() {
  curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_LOG_CHAT}&parse_mode=Markdown" > /dev/null
}

function TG_Maintainers() {
  curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_MAINTAINERS_CHAT}&parse_mode=Markdown" > /dev/null
}

function TG_News() {
  curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_NEWS_CHAT}&parse_mode=Markdown" > /dev/null
}

MESSAGE="Sync started --${CUSTOM_BUILD_TYPE}-- for ${REPO_MANIFEST_URL}"
echo $MESSAGE
TG_Logs $MESSAGE

SYNC_START=$(date +"%s")

repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))

if [ $? -eq 0 ]; then
  echo "Sync completed successfully --${CUSTOM_BUILD_TYPE}-- in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
  TG_Logs "Sync completed successfully --${CUSTOM_BUILD_TYPE}-- in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
else
  echo "Sync failed --${CUSTOM_BUILD_TYPE}-- in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
  TG_Logs "Sync failed --${CUSTOM_BUILD_TYPE}-- in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
  exit 1
fi

echo "Removing old builds zip files..."
rm -rf "$BUILD_OUTPUT_DIR"/*"${REPO_DEVICE_CODENAME}"*
echo "Done!"

echo "Initializing build..."

#Push telegram message
TG_Logs "New build started!. Date: $DATE"

source build/envsetup.sh
breakfast $BUILD_DEVICE_CODENAME
brunch $BUILD_DEVICE_CODENAME

if [ $? -eq 0 ]; then
  MESSAGE="Build completed succesfully! Uploading..."
  echo $MESSAGE
  TG_Logs $MESSAGE
  #scp ${BUILD_OUTPUT_DIR}/CleanDroidOS*-${CUSTOM_BUILD_TYPE}*.zip CleanDroidOS@frs.sourceforge.net:/home/frs/project/romname/

  if [ $UPLOAD_PUSHWAIT = 1]; then
    echo "Waiting to push OTA."
    sleep 15m
  else
    echo "No waiting to push OTA."
  fi

  FILENAME=$(find ${BUILD_OUTPUT_DIR}/CleanDroidOS*-${CUSTOM_BUILD_TYPE}*.zip | cut -d "/" -f 5)
  echo $FILENAME

  #bash ~/android/jenkins/gen_mirror_json.sh
  #cd  ~/android/ota/ && git add . && git commit -m "Update" && git push

  #Send new update message.
  TG_Logs "New update detected. Date: $SYNC_START"

  UPDATE_URL="https://sourceforge.net/projects/CleanDroidOS/files/romname/${FILENAME}/download"

  TG_Logs "Update url: $UPDATE_URL"
else
  MESSAGE="Build of date $DATE failed."
  echo $MESSAGE
  TG_Logs $MESSAGE
fi
