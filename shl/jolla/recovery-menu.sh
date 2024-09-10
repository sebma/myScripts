#!/bin/sh

####################################################################################
#
# This file is part of Jolla recovery console
#
# Copyright (C) 2013 Jolla Ltd.
# Contact: Andrea Bernabei <andrea.bernabei@jollamobile.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
####################################################################################

MOUNT_DIR=/mnt
FACTORY_ROOTFS=$MOUNT_DIR/factory-@
DEVICELOCK_SCRIPT_ABS_PATH=/usr/bin/recovery-menu-devicelock
PLUGIN=/usr/bin/restore-lock
FLASHING_SCRIPT_ABS_PATH=/usr/bin/recovery-menu-flash
# The prefix of the dirs where we will move the old subvolumes
# (we will restore them in case something goes wrong)
TMP_DIRS_PREFIX=rec-$(date +%Y%m%d_%H%M%S)

if [ -f /etc/moslo-version ]; then
  VERSION=$(cat /etc/moslo-version)
else
  VERSION="UNKNOWN"
fi

# exit immediately if a command fails
set -e

echo_err () { echo "$@" 1>&2; }

# umount_and_delete will umount and rm the dir which is passed as ARGUMENT
# Arguments: 1 dir
umount_and_delete () {
  umount_if_mounted $1

  # Whether it's mounted or not, delete the mount point, if any
  if [ -d $1 ]; then
    echo "[CLEANUP] Deleting $1"
    # this is wanted, the directories we're deleting should be empty.
    # Don't delete data if they're not
    rmdir $1 || return 1
  fi
}

umount_if_mounted () {
  local file=$1
  # If that dir is mounted, umount it
  if ( mount | grep " $file " > /dev/null ); then
    echo "[CLEANUP] Umounting $file"
    umount $file || return 1
  fi
}

is_btrfs_mounted () {
  mount | grep "$MOUNT_DIR" | awk '{print $3}' | grep "^btrfs$" > /dev/null && [ -d $FACTORY_ROOTFS ]
  return $?
}

cleanup () {
  echo "[CLEANUP] Starting cleanup!"
  cd /

  # sync any change to filesystem before cleaning up
  if is_btrfs_mounted; then
    btrfs filesystem sync $MOUNT_DIR \
      || { echo_err "[WARNING] Filesystem sync failed"; return 1; }
    sync
  fi

  echo "[CLEANUP] Umounting top volume..."
  umount_and_delete $MOUNT_DIR || return 1

  # delete the symbolic link that we have created to the /boot dir in factory-@
  if [ -L /boot ]; then
    rm /boot || { echo_err "[ERROR] Could not delete /boot symlink!"; return 1; }
  # otherwise, there could be an empty folder (maybe created during initrd build)
  # in that case, delete it
  # Don't delete it if it's not empty, because the stuff which is in there is not ours
  elif [ -d /boot ]; then
    rmdir /boot || { echo_err "[ERROR] Could not delete /boot dir!"; return 1; }
  fi
  echo "[CLEANUP] Cleanup done."
}

error_exit_and_cleanup () {
  cleanup || echo_err "[ERROR] Error encountered while cleaning up!"
  exit 1
}

#ERR signal is not supported in SH
trap cleanup SIGHUP SIGINT SIGQUIT SIGTERM

# This function deletes all the subvolumes in $MOUNT_DIR except those
# filtered by the eventual cmd passed as parameter.
# IMPORTANT: WHEN USING GREP WITH A REGEXP, THE REGEXP MUST BE QUOTED 
# AND THE QUOTES MUST BE ESCAPED!
# e.g delete_all_subvolumes_matchin_filter "grep \"this\|that\""
# ------> ONE PARAMETER: THE COMMAND WHICH SHOULD PERFORM AN EVENTUAL
#                 FILTERING ON THE LIST OF SUBVOLUMES (usually grep).
delete_all_subvolumes_matching_filter () {
  local subvolumes_list_cmd="btrfs subvolume list $MOUNT_DIR | awk '{ print \$NF }' | sort -r"
  local filter=$@
  local volumes=""

  #if the filter command has been passed -> use it...otherwise, we will delete all subvolumes
  if [[ -n "$filter" ]]
  then
    subvolumes_list_cmd="$subvolumes_list_cmd | $filter"
  fi

  volumes=`eval "$subvolumes_list_cmd"`
  for subvolume in $volumes
  do
    # If there is an error while deleting, ignore it but warn the user
    btrfs subvolume delete $MOUNT_DIR/$subvolume \
      || echo_err "[ERROR] While deleting old user data!"
  done
}

# This is needed in case restoring the factory snapshot doesn't succeed.
# In that case, we will move back the snapshots that we renamed before 
# trying to restore the factory snapshots.
# -----> ONE PARAMETER: The prefix of the pre-recovery-process folders
#                       of which we have made a backup of
try_recover_from_failed_recovery () {
  echo_err -n "[WARNING] Recovery process failed! "
  echo -n "A best-effort recovery procedure will now begin to attempt restoring "
  echo "the system state as it was before beginning the recovery process."
  local restore_failed=

  # try to restore the pre-recovery-process subvolume
  if [ -d $MOUNT_DIR/$1\_@ ]
  then
    # in case the snapshotting from factory-@ only partially succeded, 
    # we have to delete the half-born creature
    if btrfs subvolume list $MOUNT_DIR | awk '{ print $NF }' | grep "^@$\|^@/" > /dev/null
    then
      delete_all_subvolumes_matching_filter "grep \"^@$\|^@/\""
    fi
    
    # if, for whatever reason, there is a file or a directory (which is not 
    # a subvolume because we checked that above) with the same name, remove it.
    # This is also a safe measure in case for whatever reason the above 
    # "subvolume delete" commands don't work with that subvolume
    if [ -e "$MOUNT_DIR/@" ]
    then 
      rm -rf $MOUNT_DIR/@
    fi    
    
    mv $MOUNT_DIR/$1\_@ $MOUNT_DIR/@ \
      || { echo_err "[WARNING] Could not restore rootfs subvolume!"; restore_failed=yes; }
  else 
    restore_failed=yes
    echo_err "[WARNING] Error while trying to bring the situation back to pre-recovery-process state, the older user data could not be found."
  fi

  # if: we have something to restore
  if [ -d $MOUNT_DIR/$1\_@home ]
  then
    if btrfs subvolume list $MOUNT_DIR | awk '{ print $NF }' | grep "^@home$\|^@home/" > /dev/null
    then
      delete_all_subvolumes_matching_filter "grep \"^@home$\|^@home/\""
    fi

    if [ -e $MOUNT_DIR/@home ]
    then 
      rm -rf $MOUNT_DIR/@home
    fi    
    
    mv $MOUNT_DIR/$1\_@home $MOUNT_DIR/@home \
      || { echo_err "[WARNING] Could not restore home subvolume!"; restore_failed=yes; }
  else 
    restore_failed=yes
    echo_err "[WARNING] Error while trying to bring the situation back to pre-recovery-process state, the older user data could not be found."
  fi

  if [ $restore_failed ]
  then
    echo_err "[ERROR] The secondary recovery process didn't complete successfully. "
    echo "The software will now exit."
  else
    echo "[DONE] Secondary recovery: data restored."
  fi

}

setup_reset () {
  # update TMP_DIRS_PREFIX if we're starting a new recovery
  TMP_DIRS_PREFIX=rec-$(date +%Y%m%d_%H%M%S)
  ROOT=$(cat /proc/cmdline | sed -e "s/ /\\n/g" | grep ^root= | cut -d "=" -f2)
  [ -z "$ROOT" ] && echo_err "[ERROR] root= not found from /proc/cmdline" && return 1

  mkdir -p $MOUNT_DIR || { echo_err "[ERROR] Can't create $MOUNT_DIR" && return 1; }
  echo "Mounting $ROOT on $MOUNT_DIR"
  mount -o subvolid=0 $ROOT $MOUNT_DIR \
    || { echo_err "[ERROR] Can't mount '$ROOT' to '$MOUNT_DIR'" && return 1; }

  # Create a symlink to the boot folder inside factory-@
  # This is to avoid modifying the official flashing scripts
  [ -e /boot ] &&  { echo_err "[ERROR] /boot exists already!"; return 1; }
  ln -s $FACTORY_ROOTFS/boot /boot || { echo_err "[ERROR] Could not create /boot symlink!"; return 1; }

  # Ensure the devicelock script exists and is executable
  if [ -f $DEVICELOCK_SCRIPT_ABS_PATH ]; then 
    if [ ! -x $DEVICELOCK_SCRIPT_ABS_PATH ]; then
      chmod a+x $DEVICELOCK_SCRIPT_ABS_PATH \
        || { echo_err "[ERROR] chmod on devicelock script failed!"; return 1; }
    fi
    # Execute the script
    $DEVICELOCK_SCRIPT_ABS_PATH || { echo_err "[ERROR] Device access denied!"; return 1; }
  else 
    echo_err "[ERROR] Devicelock script not found!"
    return 1
  fi
  

  # Check that there we actually have factory snapshots which we can use
  ( btrfs subvolume list $MOUNT_DIR | awk '{ print $NF }' | grep -q "^factory-@$" > /dev/null) \
    &&  ( btrfs subvolume list $MOUNT_DIR | awk '{ print $NF }' | grep -q "^factory-@home$" > /dev/null) \
    || { 
         # If we get here, it means one of the factory snapshots could not be found
         echo_err "[CRITICAL] The recovery snapshots could not be found (or they are corrupted).";
         echo_err "The recovery cannot continue!"; 
         return 1; 
       }

  # Before doing the actual clean, make sure our factory snapshot is 
  # new enough and can recover home partition
  if [ 0 -lt `grep -c  "FACTORY_CLEAN_CAPABLE_IMAGE_V2" $MOUNT_DIR/factory-\@/sbin/preinit` ] &&
     [ 0 -lt `grep -c  "subvol=\@home" $MOUNT_DIR/factory-\@/etc/fstab` ] ||
     grep -q TOTAL_ERASE_SUPPORTED $MOUNT_DIR/factory-\@/usr/lib/startup/preinit/*; then
    echo "[OK] Factory snapshots found."
  else
    echo_err "[ERROR] Flashed recovery image is too old and does not support phone clearing."
    return 1
  fi

  # The plan is: 
  # - Rename @ and @home to $date_$time_@ and $date_$time_@home
  # - Snapshot factory-@ and factory-@home to @ and @home 
  #   (+ create a @swap subvol if there isn't any) to get a working system
  # - IF (no errors so far) then we should have a working system, so
  #    delete $date_$time_@ and $date_$time_@home
  # - ELSE 
  #    try to move $date_$time_@ and $date_$time_@home back to @ and @home,
  #    and EXIT WITH ERROR (sorry, recovery didn't work, but at least we 
  #    didn't delete delete your personal data and left everything the way
  #    it was before starting recovery)
  # - (OPTIONAL) Delete all user-made subvolumes (we want to clean the system) 
  #   recursively
  # - Reboot

  echo "Resetting procedure started!" 
  echo -n "Backing up current root and home subvolumes. If the backup fails, "
  echo "the old data will be deleted to let the recovery process continue."
  
  # First try "backing up" the snapshot by renaming it to something else, 
  # as we'll need its current name for the new system recovered snapshot
  if [ -d $MOUNT_DIR/@ ]; then
    # if there is already something in the destination dir, delete it.
    if [ -d $MOUNT_DIR/$TMP_DIRS_PREFIX\_@ ]; then
      rm -rf $MOUNT_DIR/$TMP_DIRS_PREFIX\_@
    fi
    mv $MOUNT_DIR/@ $MOUNT_DIR/$TMP_DIRS_PREFIX\_@
  else
    echo_err "[WARNING] The root subvolume was not found!"
  fi

  # If: something went wrong and the backup (which is actually just 
  # about renaming) was not successful, try delete it
  if [ -d $MOUNT_DIR/@ ]; then
    echo_err "[WARNING] Couldn't backup rootfs, maybe the filesystem is corruped. "
    echo "The rootfs subvolume will now be deleted to let the recovery process continue."
    delete_all_subvolumes_matching_filter "grep \"^@$\|^@/\"" 
    
    # if the dir still exists, rm'ing failed...we have to exit
    if [ -d $MOUNT_DIR/@ ]; then
      echo_err "[CRITICAL] The current system subvolumes could not be moved or deleted! "
      echo_err "The recovery process cannot continue!" 
      return 1
    fi
  fi

  if [ -d $MOUNT_DIR/@home ]; then
    # if there is already something in the destination dir, delete it.
    if [ -d $MOUNT_DIR/$TMP_DIRS_PREFIX\_@home ]; then
      rm -rf $MOUNT_DIR/$TMP_DIRS_PREFIX\_@home
    fi
    mv $MOUNT_DIR/@home $MOUNT_DIR/$TMP_DIRS_PREFIX\_@home
  else
    echo_err "[WARNING] The @home subvolume was not found!"
  fi

  # if: something went wrong and the backup (which is actually 
  # just about renaming) was not successful, try delete it
  if [ -d $MOUNT_DIR/@home ]; then
    echo_err "[WARNING] Couldn't backup $MOUNT_DIR/@home, maybe the filesystem is corruped. "
    echo "$MOUNT_DIR/@home will now be deleted to let the recovery process continue."
    delete_all_subvolumes_matching_filter "grep \"^@home$\|^@home/\""
    
    # if the dir still exists, rm'ing failed...we have to exit
    if [ -d $MOUNT_DIR/@home ]; then
      echo_err "[CRITICAL] The current system subvolumes could not be moved or deleted! "
      echo_err "The recovery process cannot continue!"
      return 1
    fi
  fi

  echo "[Done]"

  echo "Restoring factory subvolumes..."
  btrfs subvolume snapshot $MOUNT_DIR/factory-\@ $MOUNT_DIR/@ \
    || { 
         echo_err "[ERROR] Failed to recover '@' subvolume from snapshot!"
         try_recover_from_failed_recovery $TMP_DIRS_PREFIX
         return 1
       }
  btrfs subvolume snapshot $MOUNT_DIR/factory-\@home $MOUNT_DIR/@home \
    || { 
          echo_err "[ERROR] Failed to recover '@home' subvolume from snapshot!"
          try_recover_from_failed_recovery $TMP_DIRS_PREFIX
          return 1
       }
  echo "[Done]"
  
  # Look for the id of the new rootfs subvolume, and set it as default btrfs subvol
  ROOTFS_ID=$(btrfs subvolume list $MOUNT_DIR | grep " @$" | cut -d " " -f2)
  btrfs subvolume set-default $ROOTFS_ID $MOUNT_DIR \
    || { 
         echo_err "[ERROR] Failed to set default subvolume!"
         try_recover_from_failed_recovery $TMP_DIRS_PREFIX
         return 1;
       }
  
  # Force fs sync
  btrfs filesystem sync $MOUNT_DIR \
    || { 
         echo_err "[ERROR] Failed to sync filesystem data from snapshot!"
         try_recover_from_failed_recovery $TMP_DIRS_PREFIX
         return 1
       }
  sync
  
  # If: there is no @swap subvolume, create it.
  echo "Checking swap subvolume"
  if ! btrfs subvolume list $MOUNT_DIR | awk '{ print $NF }' | grep "^@swap$" > /dev/null; then
    # there is already a @swap directory but it wasn't listed in the subvolumes,
    # so it's either a corrupted subvolume or a normal dir. We'll try to remove
    # it and create a new one
    if [ -e $MOUNT_DIR/@swap ]; then 
      rm -rf $MOUNT_DIR/@swap \
        || { 
             echo_err "[ERROR] COULD NOT DELETE $MOUNT_DIR/@swap!"
             try_recover_from_failed_recovery $TMP_DIRS_PREFIX
             return 1
           }
    fi
    btrfs subvolume create $MOUNT_DIR/@swap \
      || { 
           echo_err "[ERROR] COULD NOT CREATE A NEW @swap SUBVOLUME!"
           try_recover_from_failed_recovery $TMP_DIRS_PREFIX
           return 1
         }
  else
    # TODO: SHOULD WE RECREATE THE SWAP SUBVOLUME IN ALL CASES? 
    echo "[OK] Swap subvolume found, no need to recreate it."
  fi
  echo "[DONE] Swap is ok."
  

  # Ensure flashing script exists and is executable
  if [ -f $FLASHING_SCRIPT_ABS_PATH ]; then
    if [ ! -x $FLASHING_SCRIPT_ABS_PATH ]; then
      chmod a+x $FLASHING_SCRIPT_ABS_PATH \
        || { echo_err "[ERROR] chmod on flashing script failed!"; return 1; }
    fi
  else 
    echo_err "[ERROR] Flashing script not found!"
    return 1
  fi

  echo "Running flashing scripts from recovered snapshot ..."

  # We need to do chroot to get proper path's and for that we need some mounts
  mount -t proc proc $MOUNT_DIR/@/proc
  mount -o bind /dev $MOUNT_DIR/@/dev
  mount -o bind /sys $MOUNT_DIR/@/sys

  # And copy our flashing script there
  cp $FLASHING_SCRIPT_ABS_PATH $MOUNT_DIR/@/$FLASHING_SCRIPT_ABS_PATH
  chroot $MOUNT_DIR/@/ $FLASHING_SCRIPT_ABS_PATH

  rm $MOUNT_DIR/@/$FLASHING_SCRIPT_ABS_PATH

  umount $MOUNT_DIR/@/sys
  umount $MOUNT_DIR/@/dev
  umount $MOUNT_DIR/@/proc

  if [ -f $MOUNT_DIR/@/tmp/flash-error ]; then
    rm $MOUNT_DIR/@/tmp/flash-error
    echo_err "[ERROR] Flashing script failed to run the scripts from snapshot!"
    return 1
  fi

  echo "[DONE] flashing script succeeded."

  #### THE FACTORY SNAPSHOTS HAVE BEEN RESTORED, 
  #### FROM NOW ON ANY ERROR CAN BE TREATED AS NON CRITICAL

  echo "Deleting old subvolumes"
  # This will delete all subvolumes except "@swap", "factory-@",
  # "factory-@home", "@", "@home" AND THEIR NESTED SUBVOLUMES (i.e. the subvols 
  # matching the regexp passed as parameter).
  # (this is because if a subvol "foo" has a nested subvol "fie", you have to 
  # delete "fie" to be able to delete "foo")
  # NOTE: when this function is called, @ and @home should be just snapshots 
  # of factory-@ and factory-@home (this is not a requirement, just a note 
  # on how this scripts will lay things out)
  delete_all_subvolumes_matching_filter \
    "grep -v \"^@swap$\|^@$\|^@/\|^@home$\|^@home/\|^factory-@$\|^factory-@/\|^factory-@home$\|^factory-@home/\""
  
  echo "Recovery procedure terminated SUCCESSFULLY! Now cleaning up..."
  cleanup
  echo
  echo
  echo "[DONE] DEVICE RECOVERED!"
  echo
  echo
  echo "[NOTE]: please note that since the phone will now reboot, after you press "
  echo "[Enter], this connection will be interrupted and you won't be able to interact "
  echo "with this screen anymore. If you wish to use the recovery tool again, switch "
  echo "off the phone and boot it to recovery mode again (VolDown + Power keys)."

  read -p "Press [Enter] to reboot the phone..."
  reboot_device
} 	

call_devlock_action () {
  # Ensure the devicelock script exists and is executable
  if [ -f $DEVICELOCK_SCRIPT_ABS_PATH ]; then
    if [ ! -x $DEVICELOCK_SCRIPT_ABS_PATH ]; then
      chmod a+x $DEVICELOCK_SCRIPT_ABS_PATH \
        || { echo_err "[ERROR] chmod on devicelock script failed!"; return 1; }
    fi
    # Execute the script
    $DEVICELOCK_SCRIPT_ABS_PATH $1 || { echo_err "[ERROR] Device access denied!"; return 1; }
  else
    echo_err "[ERROR] Devicelock script not found!"
    return 1
  fi
}

btrfs_recovery() {
  mount -t btrfs -o recovery,nospace_cache,clear_cache /dev/mmcblk0p28 /mnt/
  umount /mnt
  echo "Done"
  read -p "Press [Enter] to reboot the phone..."
  reboot_device
}

reboot_device () {
  /usr/bin/reboot-handler.sh
}

print_usage () {
echo "-----------------------------"
echo "     Jolla Recovery v${VERSION}      "
echo "-----------------------------"
echo "Welcome to the recovery tool!"
echo "The available options are:"
echo "1) Reset device to factory state"
echo "2) Reboot device"
echo $option3
echo "4) Shell"
echo "5) Try btrfs recovery if your device is in bootloop"
echo "6) Exit"
echo "Type the number of the desired action and press [Enter]: "
}

prompty () {
    read -p "$1 " -n 1 yn
    case $yn in
        [Yy] ) return 0;;
        * ) return 1;;
    esac
}

start_powerkey_handler () {
  /usr/bin/powerkey-handler.sh &
}

stop_powerkey_handler () {
  killall -9 powerkey-handler.sh || true
}

while true
do
  BOOTLOADER="locked"
  if $PLUGIN --is-unlocked; then
    BOOTLOADER="unlocked"
  fi
  option3="3) Bootloader unlock [Current state: $BOOTLOADER]"
  if [ -f /.time_lock ]; then
    if test `find /.time_lock -mtime +1`
    then
      rm /.time_lock
      sync
    else
      echo "Sorry too many failed lockcode attempts. And it has not been 24 hours since last attempt."
      break
    fi
  fi
  clear
  print_usage

  start_powerkey_handler

  read choice

  # Make sure we don't handle powerkey while we are in one of the menu's
  stop_powerkey_handler

  case $choice in
    1) 
      echo
      echo "ALL DATA WILL BE ERASED! Clears everything from the device and reverts the "
      echo "software back to factory state. This means LOSING EVERYTHING you have added to "
      echo "the device (e.g. updates, apps, accounts, contacts, photos and other media). "
      echo -n "Are you really SURE? "
      if prompty "[y/N]"; then
        cleanup
        setup_reset || error_exit_and_cleanup
        break
      fi
      ;;
    2) 
      reboot_device;
      ;;
    3)
      echo
      echo "If you continue, your data and bootloader will no longer be safe against "
      echo -n "attacks. This may void your warranty. Are you really SURE? "
      if prompty "[y/N]"; then
        call_devlock_action unlock || error_exit_and_cleanup
      fi
      ;;
    4)
      echo
      echo -n "If you continue, this may void your warranty. Are you really SURE? "
      if prompty "[y/N]"; then
        call_devlock_action shell || error_exit_and_cleanup
      fi
      ;;
    5)
      btrfs_recovery
      break;
      ;;
    6)
      break;
      ;;
    *) 
      echo "The option number chosen is invalid.";
      sleep 2;
      ;;
  esac
done

