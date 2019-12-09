ROMDIR=~/android/pixel
cd $ROMDIR
DATETIME=$(grep "org.pixelexperience.build_date_utc=" out/target/product/lavender/system/build.prop | cut -d "=" -f 2)
FILENAME=$(find out/target/product/lavender/PixelExperience*.zip | cut -d "/" -f 5)
ID=$(md5sum out/target/product/lavender/PixelExperience*.zip | cut -d " " -f 1)
FILEHASH=$ID
SIZE=$(wc -c out/target/product/lavender/PixelExperience*.zip | awk '{print $1}')
URL1="https://sourceforge.net/projects/lavenderbuilds/files/pixel/$FILENAME"
URL2="/download"
URL=$URL1$URL2
VERSION="10"
DONATE_URL="http:\/\/bit.ly\/jhenrique09_paypal"
WEBSITE_URL="https:\/\/download.pixelexperience.org"
NEWS_URL="https:\/\/t.me\/PixelExperience"
MAINTAINER="daniml3"
MAINTAINER_URL="https:\/\/t.me/daniiml3"
FORUM_URL="N/A"
JSON_FMT='{\n"error":false,\n"filename": %s,\n"datetime": %s,\n"size":%s, \n"url":"%s", \n"filehash":"%s", \n"version": "%s", \n"id": "%s",\n"donate_url": "%s",\n"website_url":"%s",\n"news_url":"%s",\n"maintainer":"%s",\n"maintainer_url":"%s",\n"forum_url":"%s"\n}'
printf "$JSON_FMT" "$FILENAME" "$DATETIME" "$SIZE" "$URL" "$FILEHASH" "$VERSION" "$ID" "$DONATE_URL" "$WEBSITE_URL" "$NEWS_URL" "$MAINTAINER" "$MAINTAINER_URL" "$FORUM_URL" > ~/android/ota/lavender.json
