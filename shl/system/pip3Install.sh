#!/usr/bin/env bash

function pip3Install {
	test $(id -u) == 0 && sudo="" || sudo=sudo
	if ! type -P pip3 > /dev/null; then
		if [ $(source /etc/os-release;echo $ID_LIKE) = debian ]; then
			for pkg in python3-distutils
			do
				if ! dpkg -l $pkg | \grep ^i -q;then
					echo "=> You need to install <$pkg>"
					return 1
				fi
			done
		fi
		wget -qO- https://bootstrap.pypa.io/get-pip.py | $sudo -H python3
	fi
}

pip3Install
