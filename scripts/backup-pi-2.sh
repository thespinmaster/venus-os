#!/bin/bash

IMAGE_FILENAME="${1}"
if [[ -z "${IMAGE_FILENAME}" ]]; then
 echo  "Image file name not supplied"
 read -p "Enter image file name to backup:" IMAGE_FILENAME
 if [[ -z "${IMAGE_FILENAME}" ]]; then
  return
 fi
fi

if [[  "${IMAGE_FILENAME:(-7)}" != ".img.gz" ]]; then
   IMAGE_FILENAME="${IMAGE_FILENAME}.img.gz"
fi

. /data/mount-nfs-cifs/mount-helpers.sh

SERVER=//192.168.10.30/mount
TARGET=/data/images

mount_cifs --source="${SERVER}" --target="${TARGET}"
SDCARD=$(lsblk -p -no pkname /dev/disk/by-label/root)

cat /dev/null > ~/.bash_history
rm -r -f /tmp/*

dd if=${SDCARD} iflag=fullblock bs=8M status=progress | gzip > "${TARGET}/${IMAGE_FILENAME}"

