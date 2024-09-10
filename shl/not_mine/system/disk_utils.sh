# This script is to be sourced
# Resize swap partition at boot
tlog() {
	echo `date` Disk Util: "$@"
}

# Following routine resizes all PVs in LVM called by resize_lvm_vg
resize_lvm_pv()
{
	# Add a force rescan of scsi bus to allow hotadd changed disk size
	# Note the following command is SuSE / SLES specific
	tlog "INFO: Scanning Hard disk sizes"
	rescan-scsi-bus.sh -w --forcerescan 2>&1
	# Now resize all LVM PVs
	local DEVLIST=`ls /sys/block/ | grep sd[a-z]`
	for d in $DEVLIST; do
		local DEV=/dev/${d}
		# check for partitions, filesystem, swap directly on the device and LVM.
		tlog "INFO: Resizing PV $DEV"
		if  file -s $DEV | grep -q "LVM2"; then
			pvresize $DEV 2>&1
		fi
	done
}

# Following routine resizes all VGs
resize_lvm_vg()
{
	local VGLIST=`lvdisplay | grep "LV Path"|awk '{print $3}'`
	# Call resize PVs (Doesn't hurt if called multiple times)
	resize_lvm_pv
	# Now resize all LVM LVs
	for v in $VGLIST; do
	  tlog "INFO: LV Resizing $v"
	  lvresize --resizefs -l +100%FREE "$v" 2>&1
	done
	return 0
}


#
# lists the next device that don't contain partitions, filesystems or LVM data.
#


get_next_uninitialized_device()
{
	DISKFILE=$1
	lockfile /tmp/disk.create.lockfile
	local __resultvar=$1
	local DEVLIST=`ls /sys/block/ | grep sd[a-z]`
	for d in $DEVLIST; do
		local DEV=/dev/${d}
		# check for partitions, filesystem, swap directly on the device and LVM.
		if ! file -s $DEV | grep -q "partition [[:digit:]]\+:\|filesystem data\|LVM2\|swap file\|GPT\|MBR"; then
			if ! grep -q $DEV $DISKFILE; then
				echo $DEV >> $DISKFILE
				echo $DEV
				rm -f /tmp/disk.create.lockfile
				return
			fi
		fi
	done
	rm -f /tmp/disk.create.lockfile
	echo ""
}


create_vg_lg()
{
	local VG_NAME="$1"
	local newdisk="$2"
	local LV_NAME="$3"
	local LV_FSTYPE="$4"
	local LV_MOUNTPOINT="$5"
	local LV_OPTS="$6"
	tlog "INFO: $VG_NAME on $newdisk setup started"
	set_vg "$VG_NAME" "$newdisk" || (tlog "LVM:VG $VG_NAME not created on $newdisk"; return 1)
	set_lv "$VG_NAME" "$LV_NAME" "$LV_FSTYPE" "$LV_MOUNTPOINT"\
					 "$LV_OPTS" || (tlog "LVM:LV $VG_NAME not created"; return 1)
	tlog "INFO: $VG_NAME on $newdisk setup completed"
	return 0
}
set_vg()
{
  local VG_NAME="$1"
  local newdisk="$2"
  if [ "$newdisk" != "" ]; then
	  vgcreate -s 8m -l 8 -f "$VG_NAME" "$newdisk" 2>&1 >/dev/null \
		  || (tlog "ERROR:VG $VG_NAME could not be created"; return 1)
  else
	  tlog "WARN No disk available for creating vg $VGNAME"
	  return 1
  fi
  return 0
}

set_lv()
{
		local VG_NAME="$1"
		local LV_NAME="$2"
		local LV_FSTYPE="$3"
		local LV_MOUNTPOINT="$4"
		local LV_OPTS="$5"
		lvcreate -l "100%FREE" -n "$LV_NAME" "$VG_NAME" 2>&1 > /dev/null
		if [ $? -ne 0 ]; then
			tlog "ERROR: Cannot create LV $LV_NAME."
			return 1
		fi

		if [ "${LV_FSTYPE}" == "swap" ]
		then
			# We do mkswap in recreate_swap function
			# grep for whole word here to be more accurate
			if ! (grep -qw "${VG_NAME}/${LV_NAME}" /etc/fstab); then
			  echo "/dev/${VG_NAME}/${LV_NAME} none ${LV_FSTYPE} sw,nosuid,nodev 0 0" >> /etc/fstab
			fi
			return 0
		fi
		FSOPT=""
		if [ "${LV_FSTYPE}" == "ext3" ]
		then
			 FSOPT="-q"
		fi

		if ! mkfs."$LV_FSTYPE" $FSOPT "/dev/$VG_NAME/$LV_NAME" 2>&1 > /dev/null; then
			tlog "ERROR: Cannot create a filesystem on /dev/$VG_NAME/$LV_NAME."
			return 1
		fi
		return 0
}

# The following should be called early in boot cycle to resize swap
# It is not expected that lvm autogrow may be executed everytime so
# it does resize swap logical volume (firstboot)
recreate_swap()
{
	local DEV_SWAP=/dev/sdc
	local VG_SWAP=swap_vg
	local LV_SWAP=swap1
	local LV_FSTYPE=swap
	local LV_SWAP_MAPPER=/dev/mapper/${VG_SWAP}-${LV_SWAP}
	# The disk might be blank disk might need to recreate swap_vg
	# exit if it fails with return value 1
	tlog "INFO: Recreating swap"
	vgexists=`pvs 2>/dev/null | awk "/[[:space:]]${VG_SWAP}[[:space:]]/{print \$1}"`
	if [ "$vgexists" == "" ]; then
		set_vg "${VG_SWAP}" "$DEV_SWAP" || (tlog "SWAP:VG $VG_SWAP not created on $DEV_SWAP"; return 1)
		set_lv "${VG_SWAP}" "${LV_SWAP}" "${LV_FSTYPE}" || (tlog "SWAP:LV $LV_SWAP not created"; return 1)
	fi
	# Also we need to make sure that the swap partition is resized
	# If there is no change it errors out keeping the old swapon
	pvresize "$DEV_SWAP"  || (tlog " pvresize swap failed"; return 1)
	lvresize -l +100%FREE "/dev/${VG_SWAP}/${LV_SWAP}" 2>&1 > /dev/null \
			|| (tlog " Swap resize not needed"; return 0)
	# Now swapoff and swapon the device to utilize full size
	# Best done after reboot - early in boot cycle
	# otherwise swapoff may fail
	if (/sbin/swapon -s | grep -q "${LV_SWAP_MAPPER}"); then
		/sbin/swapoff "${LV_SWAP_MAPPER}" || (tlog "SWAP:swapoff failed"; return 1)
	fi
	/sbin/mkswap -f "${LV_SWAP_MAPPER}" || (tlog "SWAP:mkswap failed"; return 1)
	/sbin/swapon "${LV_SWAP_MAPPER}" || (tlog "SWAP:swapon failed"; return 1)
	tlog "INFO: Swap resizing done"
	return 0
}

#
# lists the PVs for a given VG.
# used during firstboot. it's expected that the PVs are at the disk level, not partitions.
#
get_devices_for_vg()
{
	local VG_NAME=$1
	pvs | awk "/[[:space:]]${VG_NAME}[[:space:]]/{print \$1}"
}


#
# guesses the name of the lv that resides on device.
#
get_lv_for_device()
{
	local DEV=$1

	local VG_NAME=`pvs | grep "$DEV" | head -1 | awk '{print $2}'`

	# the LV name should be the VG without _vg suffix
	echo ${VG_NAME/%_vg/}
}


#
# creates several per-disk VGs, based on configuration file,
# and one LV in each VG.
# the disks come pre-initialized with a VG, used only as a tag
# to distinguish between them.
#
# New setup is as follows
# CloudVM has few disks populated
# 1. sda- system/root,
# 2. sdb - CloudComponents/RPM packages,
# 3. sdc - swap disk
# All other disks are assumed to be blank (either a blank vmdk or a
# dynamic disk). File systems are assigned to disks in the order they appear
# in cloudvm_disk.cfg.  Because cloudvm_disk.cfg is used both to created the
# disks in the OVF and to assign them (here), this mapping is not fragile.
#
setup_storage()
{
	local DISK_CFG=$1
	local failed=0

	if ! grep -q "^LV_CFG=" "$DISK_CFG"; then
		tlog "ERROR: LV_CFG not found."
		return 1
	fi

	if vgdisplay 2>&1 | grep -q "VG Name[[:space:]]*$VG_NAME\$"; then
		tlog "WARNING: Volume group $VG_NAME already exists."
		return 0
	fi

	echo >> /etc/fstab
	DISKFILE=$(mktemp '/tmp/XXXXdisk.reserved') ||\
	{ echo "Failed to create XXXXdisk.reserved"; exit 1; }
	grep "^LV_CFG=" "$DISK_CFG" |  ( while read line; do
		LV_CFG=$(echo $line | cut -f2 -d=)
		set -- $LV_CFG
		# see http://tldp.org/LDP/abs/html/gotchas.html#BADREAD0
		LV_NAME=$1; LV_MOUNTPOINT=$2; LV_FSTYPE=$3; LV_OPTS=$5
		VG_NAME=${LV_NAME}_vg

		if [[ "$LV_NAME" == "lvm_snapshot" ]]; then
			echo "Switching VG format for $LV_NAME"
			snapshot_lvname=lv_${LV_NAME}
			snapshot_vgname=vg_${LV_NAME}
			LV_NAME=$snapshot_lvname
			VG_NAME=$snapshot_vgname
		fi
		echo "Creating disk with VG $VG_NAME, LV $LV_NAME"
		local newdisk=`get_next_uninitialized_device $DISKFILE`
		# create_vg_lg used to executed in parallel, refer to PR 1585511 & 1608127
		create_vg_lg "$VG_NAME" "$newdisk" "$LV_NAME" "$LV_FSTYPE" \
					 "$LV_MOUNTPOINT" "$LV_OPTS"
		if ! mkdir -p "$LV_MOUNTPOINT" 2>&1 > /dev/null; then
			tlog "ERROR: Cannot create mountpoint $LV_MOUNTPOINT."
			failed=1
		elif ! (grep -qw "${VG_NAME}/${LV_NAME}" /etc/fstab); then
		  echo "/dev/$VG_NAME/$LV_NAME $LV_MOUNTPOINT $LV_FSTYPE $LV_OPTS 0 2" >> /etc/fstab
		fi
	 done
	 rm -f $DISKFILE
	 if [ "$failed" -eq "1" ]; then
		return 1
	 fi
	)
	tlog "INFO: All filesystems created. Mounting all"
	if ! mount -a; then
		tlog "ERROR: Cannot mount all filesystems."
		return 1
	fi
	# PR#3006185
	if grep -qw "VMware Photon OS 4.0" /etc/photon-release; then
		tlog "INFO: Daemon reload and restart local-fs.target."
		if ! systemctl daemon-reload; then
			tlog "ERROR: Dameon reload failed."
			return 1
		fi
		if ! systemctl restart local-fs.target; then
			tlog "ERROR: Failed to restart local-fs.target."
			return 1
		fi
	fi
}


#
# expands LVs into new disk free space.
#
lvm_autogrow()
{
	# we don't handle brand new disks
	# The user has to manually do vgcreate
	# or vgextend to add it to existing VG

	# For existing VGs just call resize_lvm_vg
	resize_lvm_vg
	return $?
}
