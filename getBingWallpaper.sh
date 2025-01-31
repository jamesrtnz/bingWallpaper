#!/bin/bash

if [ -z "$1" ]; then
   idx=1
else
   idx=$1
fi

# $bing is needed to form the fully qualified URL for
# the Bing pic of the day
bing="www.bing.com"

# $xmlURL is needed to get the xml data from which
# the relative URL for the Bing pic of the day is extracted
#
# The mkt parameter determines which Bing market you would like to
# obtain your images from.
# Valid values are: en-US, zh-CN, ja-JP, en-AU, en-UK, de-DE, en-NZ, en-CA.
#
# The idx parameter determines where to start from. 0 is the current day,
# 1 the previous day, etc.
xmlURL="https://${bing}/HPImageArchive.aspx?format=xml&idx=${idx}&n=1&mkt=en-NZ"
jsURL="https://${bing}/HPImageArchive.aspx?format=js&n=${idx}&mkt=en-NZ"

# $saveDir is used to set the location where Bing pics of the day
# are stored.  $HOME holds the path of the current user's home directory
saveDir="$HOME/BingDesktopImages/"

# Create saveDir if it does not already exist
[ ! -d "$saveDir" ] && mkdir -p $saveDir

# The desired Bing picture resolution to download
# Valid options: "_1024x768" "_1280x720" "_1366x768" "_1920x1200"
#desiredPicRes="_1920x1080"
desiredPicRes="UHD"
#desiredPicRes="_1920x1200"

# The file extension for the Bing pic
picExt=".jpg"

declare -a urls

# Parse Bing and acquire picture URL(s)
read -d '' -r -a urls < <(curl -sL "$jsURL" | \
    /opt/homebrew/bin/jq -r '.images | reverse | .[] | .url' | \
    sed -e "s/\(.*\)/https:\/\/${bing}\1/")

# Read and process the array of URLs
for p in "${urls[@]}"; do
    # Extract the relative URL of the Bing pic of the day from
    # the XML data retrieved from xmlURL, form the fully qualified
    # URL for the pic of the day, and store it in $picURL

    # Form the URL for the desired pic resolution
    desiredPicURL=$(echo $p|sed -e "s/[[:digit:]]\{1,\}x[[:digit:]]\{1,\}/$desiredPicRes/")

    # Form the URL for the default pic resolution
    defaultPicURL="$p"

    # Extract the picture filename
    picFilename=$(echo "$p" | sed -e 's/.*[?&;]id=\([^&]*\).*/\1/' | sed 's/_1920x1080//')

    # Attempt to download the desired image resolution. If it doesn't
    # exist then download the default image resolution
    if /opt/homebrew/bin/wget --quiet --spider "$desiredPicURL"
    then
      # Download the Bing pic of the day at desired resolution
      /usr/bin/curl -s -o ${saveDir}/${picFilename} $desiredPicURL
    else
      # Download the Bing pic of the day at default resolution
      /usr/bin/curl -s -o ${saveDir}/${picFilename} $defaultPicURL
    fi

done

# Remove pictures older than 30 days
find ${saveDir}/ -ctime +30 -delete

# Exit the script
exit
