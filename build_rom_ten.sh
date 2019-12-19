#!/bin/bash

# Import custom config
source $1

BUILD_OUTPUT_DIR="out/target/product/${jk_device_codename}"

BUILD_DATETIME=$(date +"%Y%m%d-%H:%i")

function TG_Logs() {
  if [ "${TG_BOT_LOG_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=*[${CLEAN_BUILD_TYPE}/${jk_device_codename}]:* ${*}&chat_id=${TG_BOT_LOG_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

function TG_Maintainers() {
  if [ "${TG_BOT_MAINTAINERS_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=*[${CLEAN_BUILD_TYPE}/${jk_device_codename}]:* ${*}&chat_id=${TG_BOT_MAINTAINERS_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

function TG_News() {
  if [ "${TG_BOT_NEWS_CHAT}" != "" ]; then
    curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendmessage" --data "text=*[${CLEAN_BUILD_TYPE}/${jk_device_codename}]:* ${*}&chat_id=${TG_BOT_NEWS_CHAT}&parse_mode=Markdown" > /dev/null
  fi
}

echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_DIR=/home/ccache/${SRV_USERNAME}
ccache -M 200G

# Repo clean
if [ "${jk_repo_clean}" = "yes" ]; then
  MESSAGE="Repo clean in progress..."
  echo $MESSAGE
  TG_Logs $MESSAGE

  rm -rf .repo

  MESSAGE="Repo clear, init new repo..."
  echo $MESSAGE
  TG_Logs $MESSAGE

  repo init -u ${REPO_MANIFEST_URL} -b ten

  MESSAGE="Repo init successfully"
  echo $MESSAGE
  TG_Logs $MESSAGE
fi

# Repo sync
if [ "${jk_repo_sync}" = "yes" ]; then
  echo "Sync started"
  TG_Logs "Sync started for *${jk_manifest_branch}* branch"

  SYNC_START=$(date +"%s")

  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

  SYNC_END=$(date +"%s")
  SYNC_DIFF=$((SYNC_END - SYNC_START))

  if [ $? -eq 0 ]; then
    echo "Sync completed successfully"
    TG_Logs "Sync completed successfully in *$((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds*"
  else
    echo "Sync failed"
    TG_Logs "Sync failed in *$((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds*"
    exit 1
  fi
fi

# Its Clean Time
if [ "$jk_make_clean" = "yes" ]; then
  make clean && make clobber
  wait
  echo -e ${cya}"OUT dir from your repo deleted"${txtrst};
  TG_Log "OUT dir from your repo deleted"
else
  echo "Removing old builds zip files..."
  #rm -rf "$BUILD_OUTPUT_DIR"/*"${jk_device_codename}"*
  echo "Done!"
fi

echo "Initializing build..."
TG_Logs "New build started!. Date: ${BUILD_DATETIME}"

# Start building
#. build/envsetup.sh
#lunch clean_"${jk_device_codename}"-userdebug
#make bacon -j$(nproc --all)

if [ $? -eq 0 ]; then
  MESSAGE="Build completed succesfully!"
  echo $MESSAGE
  TG_Logs $MESSAGE

  FILENAME=$(find ${BUILD_OUTPUT_DIR}/CleanDroidOS*.zip | cut -d "/" -f 5)

  bash /home/${SRV_USERNAME}/OTA/gen_mirror_json.sh ${jk_device_codename} ${BUILD_OUTPUT_DIR} v10.0 ${CLEAN_BUILD_TYPE}
  #cd  /home/${SRV_USERNAME}/OTA/ && git add . && git commit -m "New ${CLEAN_BUILD_TYPE} for ${jk_device_codename} update" && git push

  #Send new update message.
  TG_Logs "New update detected. Date: ${BUILD_DATETIME}"

  UPDATE_URL="https://sourceforge.net/projects/cleandroidos/files/${CLEAN_BUILD_TYPE}/v10.0/${jk_device_codename}/${FILENAME}/download"

  TG_Logs "Update available in 15 minutes on url: ${UPDATE_URL}"
else
  MESSAGE="Build of date ${BUILD_DATETIME} failed."
  echo $MESSAGE
  TG_Logs $MESSAGE
  exit 1
fi
