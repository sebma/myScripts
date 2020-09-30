#!/usr/bin/env sh

scriptBaseName=$(basename $0)
if [ $USER != root ];then
	echo "=> ERROR : You must run $scriptBaseName as root." >&2
	exit 1
fi

for newSudoUser
do
	id -un $newSudoUser >/dev/null 2>&1 || useradd -m $newSudoUser
	for group in admin sudo wheel
	do
		grep -qw $group /etc/group && usermod -aG $group $newSudoUser
		\sed -i "/$group ALL=(ALL) ALL/s/#[ 	]*//" /etc/sudoers
	done
	passwd $newSudoUser
done
