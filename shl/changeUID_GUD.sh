#!/usr/bin/env ksh

test $# != 3 && {
	echo "=> Usage: <" >&2
	exit 1
}

sudo usermod -u NEWUID LOGIN
sudo groupmod -g NEWGID GROUP
find / -user OLDUID -exec chown -h NEWUID {} \;
find / -group OLDGID -exec chgrp -h NEWGID {} \;
sudo usermod -g NEWGID LOGIN
