#!/bin/bash
# TAKEN FROM https://gist.github.com/nublaii/f2f3ee92a392a8abaca055d28c821e21

exit 0
#
# Sysprep OS for vmware template creation.
#

echo "Removing openssh-server's host keys..."
rm -vf /etc/ssh/ssh_host_*

echo "Creating rc.local..."
cat /dev/null > /etc/rc.local
chmod +x /etc/rc.local
cat << EOF >> /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

if [ ! -f /swapfile ]
then
	dd if=/dev/zero of=/swapfile bs=1M count=2048 > /dev/null 2>&1
	chmod 600 /swapfile > /dev/null 2>&1
	mkswap /swapfile > /dev/null 2>&1
	swapon /swapfile > /dev/null 2>&1
fi

if [ ! -f /etc/ssh/ssh_host_rsa_key ]
then
  dpkg-reconfigure openssh-server > /dev/null
fi

exit 0
EOF

echo "Cleaning up /var/mail..."
rm -vf /var/mail/*

echo "Clean up apt cache..."
find /var/cache/apt/archives -type f -exec rm -vf \{\} \;

echo "Clean up ntp..."
rm -vf /var/lib/ntp/ntp.drift
rm -vf /var/lib/ntp/ntp.conf.dhcp

echo "Clean up dhcp leases..."
rm -vf /var/lib/dhcp/*.leases*
rm -vf /var/lib/dhcp3/*.leases*

echo "Clean up udev rules..."
rm -vf /etc/udev/rules.d/70-persistent-cd.rules
rm -vf /etc/udev/rules.d/70-persistent-net.rules

echo "Clean up urandom seed..."
rm -vf /var/lib/urandom/random-seed

echo "Clean up backups..."
rm -vrf /var/backups/*;
rm -vf /etc/shadow- /etc/passwd- /etc/group- /etc/gshadow- /etc/subgid- /etc/subuid-

echo "Cleaning up /var/log..."
find /var/log -type f -name "*.gz" -exec rm -vf \{\} \;
find /var/log -type f -name "*.1" -exec rm -vf \{\} \;
find /var/log -type f -exec truncate -s0 \{\} \;

echo "Clearing bash history..."
cat /dev/null > /root/.bash_history
history -c

echo "Compacting drive..." # VOIR AUSSI L'OUTIL "zerofree" sur https://askubuntu.com/a/1220639/426176
dd if=/dev/zero of=/EMPTY bs=1M > /dev/null
sync
rm -vf /EMPTY
sync

echo "Clearing bash history (II)..."
cat /dev/null > /root/.bash_history
history -c

echo "Process complete..."
poweroff
