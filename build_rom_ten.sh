#!/bin/bash

# Import custom config
source $1

TARGET_GAPPS_ARCH=arm64

BUILD_OUTPUT_DIR="out/target/product/${jk_device_codename}"

BUILD_DATETIME=$(date +"%Y%m%d-%H:%m:%s")

function TG_Logs() {
  if [ "${TG_BOT_LOG_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_LOG_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

function TG_Maintainers() {
  if [ "${TG_BOT_MAINTAINERS_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_MAINTAINERS_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

function TG_News() {
  if [ "${TG_BOT_NEWS_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=${*}&chat_id=${TG_BOT_NEWS_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_DIR=/home/ccache/${SRV_USERNAME}
ccache -M 200G

# Repo clean
if [ "${jk_repo_clean}" = "yes" ]; then
  MESSAGE="${CLEAN_BUILD_TYPE}: Repo clean in progress..."
  echo $MESSAGE
  TG_Logs $MESSAGE

  rm -rf .repo

  MESSAGE="${CLEAN_BUILD_TYPE}: Repo clear, init new repo..."
  echo $MESSAGE
  TG_Logs $MESSAGE

  repo init -u ${REPO_MANIFEST_URL} -b ten

  MESSAGE="${CLEAN_BUILD_TYPE}: Repo init successfully"
  echo $MESSAGE
  TG_Logs $MESSAGE
fi

# Repo sync
if [ "${jk_repo_sync}" = "yes" ]; then
  echo "Sync started"
  TG_Logs "Sync started *${CLEAN_BUILD_TYPE}* for *${jk_manifest_branch}* branch"

  SYNC_START=$(date +"%s")

  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))

  if [ $? -eq 0 ]; then
    echo "Sync completed successfully"
    TG_Logs "Sync completed successfully *${CLEAN_BUILD_TYPE}* in *$((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds*"
  else
    echo "Sync failed"
    TG_Logs "Sync failed *${CLEAN_BUILD_TYPE}* in *$((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds*"
    exit 1
  fi
fi

if [ "${jk_repo_clean}" = "yes" ]; then
  echo "Removing out directory..."
  rm -rf "$BUILD_OUTPUT_DIR"
  echo "Done!"
else
  echo "Removing old builds zip files..."
  rm -rf "$BUILD_OUTPUT_DIR"/*"${jk_device_codename}"*
  echo "Done!"
fi

echo "Initializing build..."
TG_Logs "New build started!. Date: ${BUILD_DATETIME}"

# Start building
. build/envsetup.sh
lunch clean_"${jk_device_codename}"-userdebug
make bacon -j$(nproc --all)

if [ $? -eq 0 ]; then
  MESSAGE="Build completed succesfully! Uploading..."
  echo $MESSAGE
  TG_Logs $MESSAGE

  if [ "${CLEAN_BUILD_TYPE}" = OFFICIAL]; then
    #scp ${BUILD_OUTPUT_DIR}/CleanDroidOS*-${CLEAN_BUILD_TYPE}*.zip CleanDroidOS@frs.sourceforge.net:/home/frs/project/romname/

    echo "Waiting to push OTA."
    sleep 15m

    FILENAME=$(find ${BUILD_OUTPUT_DIR}/CleanDroidOS*.zip | cut -d "/" -f 5)
    #echo $FILENAME

    #bash ~/android/jenkins/gen_mirror_json.sh
    #cd  ~/android/ota/ && git add . && git commit -m "Update" && git push

    #Send new update message.
    TG_Logs "New update detected. Date: ${BUILD_DATETIME}"

    UPDATE_URL="https://sourceforge.net/projects/CleanDroidOS/files/romname/${FILENAME}/download"

    TG_Logs "Update url: ${UPDATE_URL}"
  fi

  echo "Filename: " $(find ${BUILD_OUTPUT_DIR}/CleanDroidOS*.zip | cut -d "/" -f 5)
else
  MESSAGE="Build of date ${BUILD_DATETIME} failed."
  echo $MESSAGE
  TG_Logs $MESSAGE
  exit 1
fi
