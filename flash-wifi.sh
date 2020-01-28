#!/bin/bash
while getopts u:n:d:i:s:p: option
do
case "${option}"
in
u) USERDATA=${OPTARG};;
n) HOSTNAME=${OPTARG};;
d) TARGET_DEVICE=${OPTARG};;
i) SOURCE_IMAGE=${OPTARG};;
s) SSID=${OPTARG};;
p) PSK=${OPTARG};;
esac
done

TEMP="temp-${USERDATA}"
EXTN=".orig"

# Simple wrapper for Hypriot Flash, to update the Wifi Credentials in a custom user-data file
#   assumes Hypriot Flash is already installed
echo "** copying user-data [${USERDATA}] to temp file [${TEMP}] **"
cp ${USERDATA} ${TEMP}

echo "** replacing wifi creds in temp file **"
sed -i ${EXTN} -e "/^#/!s/.*ssid=.*\$/      ssid=\"${SSID}\"/" ${TEMP}
sed -i ${EXTN} -e  "/^#/!s/.*psk=.*\$/      psk=\"${PSK}\"/" ${TEMP}
rm "${TEMP}${EXTN}"

echo "** flashing SD card [${TARGET_DEVICE}] **"
flash -u ${TEMP} -n ${HOSTNAME} -d ${TARGET_DEVICE} ${SOURCE_IMAGE}

echo "** cleaning up temp file [${TEMP}] **"
rm ${TEMP}



## ideally make a cross-platform script using dd to flash, to remove the dependancy on Hypriot Flash (I ran into write permission issues in Ubuntu)
#  dd if=/dev/sda of=/dev/sdb

# # I get resource busy on MacOS with the below...
# dd if=${SOURCE_IMAGE} of=${TARGET_DEVICE} bs=4m

# # MacOS
# echo "** replacing user-data in flashed device **"
# cp ${TEMP} /Volumes/HypriotOS/user-data