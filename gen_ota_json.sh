#!/bin/bash

CMD_DEVICE_CODENAME=$1
CMD_DEVICE_OUT=$2
CMD_CLEAN_VERSION=$3
CMD_CLEAN_BUILD_TYPE=$4

DATETIME=$(grep "ro.build.date.utc=" ${CMD_DEVICE_OUT}/system/build.prop | cut -d "=" -f 2)
FILENAME=$(find ${CMD_DEVICE_OUT}/CleanDroidOS-*.zip | cut -d "/" -f 5)
FILEHASH=$(md5sum ${CMD_DEVICE_OUT}/CleanDroidOS-*.zip | cut -d " " -f 1)
FILESIZE=$(wc -c ${CMD_DEVICE_OUT}/CleanDroidOS-*.zip | awk '{print $1}')
DOWNLOAD_URL="https://sourceforge.net/projects/cleandroidos/files/${CLEAN_BUILD_TYPE}/${CMD_CLEAN_VERSION}/${CMD_DEVICE_CODENAME}/${FILENAME}/download"

msg=$(mktemp)
{
  echo -e "{"
  echo -e "  \x22response\x22: ["
  echo -e "    {"
  echo -e "      \x22datetime\x22: ${DATETIME},"
  echo -e "      \x22filename\x22: \x22${FILENAME}\x22,"
  echo -e "      \x22id\x22: \x22${FILEHASH}\x22,"
  echo -e "      \x22size\x22: ${FILESIZE},"
  echo -e "      \x22romtype\x22: \x22${CMD_CLEAN_BUILD_TYPE}\x22,"
  echo -e "      \x22url\x22: \x22${DOWNLOAD_URL}\x22,"
  echo -e "      \x22version\x22: \x22${CMD_CLEAN_VERSION}\x22"
  echo -e "    }"
  echo -e "  ]"
  echo -e "}"
} > "${msg}"

BJSON=$(cat "${msg}")
echo "Generate OTA JSON completed"
echo "${BJSON}" > "${CMD_DEVICE_OUT}/${FILENAME}.json"
