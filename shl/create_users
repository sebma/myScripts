#!/usr/bin/env sh

primaryGroup=soltech
secondaryGroupList="users meeur"
sudo -v
for user
do
	id $user >/dev/null 2>&1 || sudo adduser --ingroup $primaryGroup $user
	id $user >/dev/null 2>&1 && {
		for group in $secondaryGroupList
		do
			groups $user | grep -q $group || sudo adduser $user $group
		done
	}
done
