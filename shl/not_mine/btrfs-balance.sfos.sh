#!/usr/bin/env bash
#cf. https://github.com/sailfishos/btrfs-balancer/tree/master/scripts

if ! awk -F= '/^ID=/{print$2}' /etc/os-release | grep -q sailfishos;then
	echo "=> [$0] ERROR : This script must be run on sailfishos." >&2
	exit 1
fi

ROOTDEV=/dev/mmcblk0p28

USED=0
RAWUSE=0
MAXUSE=0
FREE_SPACE=0
btrfs="sudo $(which btrfs)"

# Threshold for percentage of free space allocation to run balance
BALANCE_THRESHOLD=75
# Threshold of battery charge
CHARGE_THRESHOLD=25

print_help()
{
	printf "  Usage: btrfs-balance [OPTIONS]\n\n"
	printf "  OPTIONS:\n"
	printf "      -d <dev>  Specify root device on which to run the balance on.\n"
	printf "                If omitted, default is /dev/mmcblk0p28\n"
	printf "      -t <prct> Set allocation threshold percent [0,100] at which to\n"
	printf "                start balance. If omitted, default is 75 %%\n"
	printf "      -c <prct> Set battery charge threshold percent [0,100] at which to\n"
	printf "                allow balance operation. If omitted, default is 25 %%\n"
	printf "      -f        Print amount of free unallocated space on root device in MiB\n"
	printf "      -h        Print this help\n"
}

get_usages()
{
	MAXUSE=$($btrfs fi show 2>&1 | grep $ROOTDEV | \
			awk -F ' ' '{print $4}'| grep -o '[0-9.]*')
	RAWUSE=$($btrfs fi show 2>&1 | grep $ROOTDEV | \
			awk -F ' ' '{print $6}'| grep -o '[0-9.]'*)
	FREE_SPACE=$(awk -v rawuse="$RAWUSE" -v maxuse="$MAXUSE" \
			'BEGIN {printf "%d\n", 1000 * maxuse - 1000 * rawuse}')
}

get_used()
{
	get_usages
	USED=$(awk -v rawuse="$RAWUSE" -v maxuse="$MAXUSE" \
			'BEGIN {printf "%d\n", rawuse * 100 / maxuse}')
}

check_balance_need()
{
	get_used

	if test "$USED" -ge "$BALANCE_THRESHOLD"; then
		echo "$USED % of space allocated, threshold is $BALANCE_THRESHOLD %, balancing needed"
	else
		echo "No need for balance: $USED % allocated, balance limit $BALANCE_THRESHOLD %"
		return 0
	fi

	CHARGE_NOW=$(cat /run/state/namespaces/Battery/ChargePercentage)
	IS_CHARGING=$(cat /run/state/namespaces/Battery/IsCharging)

	if test "$CHARGE_NOW" -lt "$CHARGE_THRESHOLD" && test "$IS_CHARGING" -eq 0; then
		echo "Cannot balance, battery charge is too low. Please, plug in charger" >&2
		exit 1
	fi
	return 1
}

report_progress()
{
	echo "BALANCE_PROGRESS:$1"
}

while getopts "d:t:c:fh" opt; do
	case $opt in
	d)
		if ! test -e "$OPTARG"; then
			echo "Root device \"$OPTARG\" does not exist!" >&2
			exit 1
		fi
		ROOTDEV="$OPTARG"
	;;
	t)
		if test "$OPTARG" -ge 0 && test "$OPTARG" -le 100; then
			BALANCE_THRESHOLD=$OPTARG
		else
			echo "Error: -t $OPTARG is out of 0-100 range!"
			exit 1
		fi
	;;
	c)
		if test "$OPTARG" -ge 0 && test "$OPTARG" -le 100; then
			CHARGE_THRESHOLD=$OPTARG
		else
			echo "Error: -c $OPTARG is out of 0-100 range!"
			exit 1
		fi
	;;
	f)
		show_usages=1
	;;
	h)
		print_help
		exit 0
	;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		print_help
		exit 1
	;;
	*)
		print_help
		exit 1
	;;

	esac
done
shift $(($OPTIND-1))

if ! [ -e $ROOTDEV ]; then
	echo "=> ERROR: $ROOTDEV does not exist." >&2
	exit 2
fi

[ "$show_usages" = 1 ] && get_usages && echo "$FREE_SPACE" && exit 0

if test check_balance_need; then
	# We start from empty block groups and advance to more full ones.
	echo "Starting btrfs balance, please leave device idle during balance"
	for usage in 0 10 20 35 50 75 96; do
		report_progress $usage
		if ! $btrfs balance start -dusage=$usage /; then
			echo "Btrfs balance failed while freeing $usage % full block groups"
			exit 28 #ENOSPC
		fi
	done
	report_progress 100
fi

echo "Btrfs balance finished"
exit 0
