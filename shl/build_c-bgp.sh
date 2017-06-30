#!/usr/bin/env bash

set -o errexit

function buildSourceCode {
	if [ ! -s configure ]
	then
		time ./bootstrap.sh || time ./autogen.sh
	fi
	if [ ! -s Makefile ]
	then
		time ./configure $@
	fi
	if [ -s Makefile ] || [ -s GNUmakefile ]
	then
		if time make
		then
			if test -w $prefix 
			then
				make install
			else
				sudo make install
			fi
		fi
	fi
}

function buildFromGit {
	local url=$1
	[ "$http_proxy" ] && git config --global http.proxy
	mkdir -p ~/src && cd ~/src
	git clone $url || {
		cd $(basename $url) && git pull && cd -
	}
	if cd $(basename $url)
	then
		buildSourceCode --prefix=$prefix
	fi
}

function buildFromArchive {
	local url=$1
	mkdir -p ~/src && cd ~/src
	wget --no-check-certificate $url
	archiveName=$(basename $url)
	archiveExtension=tar.gz
	tar xzf $archiveName
	if cd $(basename $url .$archiveExtension)
	then
		buildSourceCode --prefix=$prefix
	fi
}

function main {
	local firstArg=$1
	set -o nounset
	which cbgp || {
		if [ "$firstArg" ]
		then
			prefix=$1
			shift
		else
			groups | grep -q sudo && prefix=/usr/local || prefix=$HOME/local
		fi

		pkg-config libgds --modversion || {
			buildFromArchive http://netcologne.dl.sourceforge.net/project/libgds/libgds-2.2.2.tar.gz
			env | grep -q PKG_CONFIG_PATH && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$prefix/lib/pkgconfig || export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
		}
#		pkg-config libgds --modversion && buildFromGit https://github.com/lvanbever/cbgp
		pkg-config libgds --modversion && buildFromArchive http://netcologne.dl.sourceforge.net/project/c-bgp/cbgp-2.3.2.tar.gz
		echo
		uname | grep -q Linux && ls --color -l $prefix/bin/cbgp || ls -lF $prefix/bin/cbgp
	}
}

main $@
