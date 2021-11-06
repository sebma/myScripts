#!/usr/bin/env sh

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo)
simpleUserGroups=""
for userName
do
	id $userName 2>/dev/null || {
		$sudo addgroup $userName
		$sudo adduser $userName
		for group in $userName $simpleUserGroups
		do
			groups $userName | grep -q $group || $sudo adduser $userName $group
		done
	}
done

