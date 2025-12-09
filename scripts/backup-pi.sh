#!/bin/bash

# use echo $(<./backup-pi-proxmox.log) to get progress updates

IMAGES_PATH=/mnt/storage/images/

if [[ -n "${2}" ]]; then
  if [[ ! -f "${2}" ]]; then
    echo "Could not find file \'${1}\'; exiting..."
    exit
  fi

  IMAGE_FILENAME="${2}"

  if [[ -n "${1}" ]]; then

    # final check that we have an device path
    if [[ $(lsblk -dnpo name | grep "^${1}$") ]]; then
      DISK="${1}"
      sudo dd if="${DISK}" iflag=fullblock bs=8M status=progress | gzip > "${IMAGE_FILENAME}"
      echo "completed" >> "${0%.*}".log
      exit
    else
      echo "invalid device path:${2}; exiting..."
      exit
    fi
  fi

else

 read -p "Enter image file name to backup:" IMAGE_FILENAME

fi

if [[ -z "${IMAGE_FILENAME}" ]]; then
  echo "no image file name supplied; Exiting..."
  return
fi

# -e 11 (exclude CDROM drives")

echo
if [[ -z $(lsblk -e 11 -o rm | grep " 1") ]]; then
   echo "no removable disks found; exiting..."
   exit
fi

echo "=Disks==========================================================="
echo "$(lsblk -e 11 -o name,size,type,tran,model,rm)" #| grep " 1$" | sed 's![^ ]*$!!')
echo "================================================================="

  # create an array with all the filer/dir inside ~/myDir
  PS3='Select the sdcard to backup (or CTRL+C):'

  # Choose the disk to restore to.
  # grep "1 disk$" is filtering only the removable disks. the 1 is the removable column.
  # -n=no headers,-d=no partitions, o= xxx,xxx=columns to return'
  # cut trims the end of the string so only the device path is displayed
  select DISK in $(lsblk -p -ndo name,rm,type | grep "1 disk$" | cut -d ' ' -f 1)
  do
    # complain if no file was selected, and loop to ask again
    if [[ -z "${DISK}" ]]; then
      echo "${REPLY} is not a valid number"
      continue
    fi

    # now we can use the selected file
    echo "\'${DISK}\' selected"

    # it'll ask for another unless we leave the loop
    break
  done

echo
echo "backing up disk ${DISK} to image ${IMAGES_PATH}${IMAGE_FILENAME}"
read -p "Do you want to proceed? (y/n) " confirm

case "${confirm}" in
	y ) echo;;
	n ) echo exiting...;
          exit;;
	* ) echo invalid response;
          continue;;
esac

# dummy sudo ls (ls could be any call) to elevate
# permissions before the nohup call
sudo ls 1>/dev/null 2>/dev/null

# here we use nohup so that the process works in the background and
# can logout of ssh terminals.
# we call this script again with the args we have set
# this is so that nohup names the process with the name of this script
# so its easy to find and kill if required.
echo 'use `echo $(<./restore-pi.log)` to get progress updates'

nohup "${0}" "${DISK}" "${IMAGES_PATH}${IMAGE_FILENAME}" > "${0%.*}".log &

sleep 1
tail -f "${0%.*}".log
