#!/bin/bash
# Check to see if raspbian exists on hard drive
ls *raspbian*.img >/dev/null 2> /dev/null
if [ "$?" -eq "1"  ]; then
  # file not found
  raspbianFileName='raspbian.img'
else
  # file found
  raspbianFileName=$(ls *raspbian*.img | head -n1) > /dev/null
fi


if [[ -e $raspbianFileName ]]; then
  echo "Raspbian found in $raspbianFileName"
else
  # the file does not exist
  echo -e "Raspbian not found. Download? \c"
  read shouldDownload
  case "$shouldDownload" in
    Y|y|yes|Yes|YES) # regex for anything starting with Y
      echo "Attempting to download..."
      downloadURL='downloads.raspberrypi.org/raspbian_latest' # needs redirects
      curl -L downloads.raspberrypi.org/raspbian_latest -o 
      CURLcode=$?
      if [ "$CURLcode" -eq "0" ]; then
        echo "Download successful"
      else
        echo "File download not successfully."
        echo "Curl returned code $CURLcode. For more details type 'man curl'"
        exit 1 # exit this program with error code 1
      fi 
      # Attempt to unzip the file
      $raspbianDownloadFileName = ls 
      unzip "$raspbianDownloadFileName" 
      mv *.img "$raspbianFileName"
      # TODO: Check success in script
      # TODO: Check to see if unzip exists on system and propose alternatives (Linux doesn't have I know)
      ;;
      N|n|no|No|NO) # regex for anything starting with N
      echo "Aborting install"
      exit 3 # exit program with exit status 3. TODO: Ask user for other file
      ;;
  esac
    
fi

ls -lh $raspbianFileName # for verification

echo -e "Is this the correct file? \c"
read correctFile
case $correctFile in
  Y|y|yes|Yes|YES)
    echo "Using $raspbianFileName"
    ;;
  N|n|no|No|NO)
    echo -e "Enter full path to raspbian.img: \c"
    read raspbianFullPath
    if [[ -e $raspbianFullPath ]]; then
      echo "Raspbian found in $raspbianFullPath"
    else
      echo "Raspbian not found. Try running script again."
      exit 2 # exit program with exit status 2.
    fi
esac

# We now assume that the raspbian image is at $raspbianFullPath

echo '
Please select a disk from the following output to write raspbian to. Be warned 
that this will OVERWRITE all data on the disk. Check and double check.

Note, the name should be (example) /dev/disk1, not /dev/disk1s1 for MacOS,
and (example) /dev/sdb, not /dev/sdb1 for Linux.'

diskutil list #this has been texted only on MacOS, not on Linux

echo -e "Disk identifier?: \c"
read diskname

# Fix diskname for common errors
diskname=$(echo $diskname | sed -e 's/\(disk[0-9]\)s[0-9]/\1/g')
diskname=$(echo $diskname | sed -e 's/\(sd[a-z]\)[0-9]/\1/g')
diskname=$(echo $diskname | sed -e 's/\(\/dev\/\)*\(.*\)/\/dev\/\2/g')  

if hash pv 2>/dev/null; then
  filesize=$(wc -c "$raspbianFileName" | cut -f2 -d' ')
  command="cat $raspbianFileName | pv -s $filesize | sudo dd of=$diskname bs=1m"
  command="pv $raspbianFileName | sudo dd of=$diskname bs=1m"
else
  command="dd if=$(pwd)/$raspbianFileName bs=1m of=$diskname"
fi

# check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Type or copy/paste the following command."
  echo -e "Note, (On some systems running coreutils you may need '1M' instead of '1m')\n"
  echo sudo $command
elif [ "$EUID" -eq 0 ]; then
  echo "Unmounting $diskname..."
  diskutil unmountDisk "$diskname"
  echo $command
  sleep 2
  eval $command
fi

exit 0 # exit this program with error code 0 (success)
