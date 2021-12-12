#!/usr/bin/env bash

prefix=$HOME/local

function buildSourceCode {
    test "$1" = "-h" && { 
        echo "=> Usage: $FUNCNAME [--prefix=/installation/path] [./configure arguments ...]" 1>&2
        return 1
    }
    if [ $# = 0 ]; then
        if groups | egrep --color -wq "sudo|adm|root"; then
            prefix=/usr/local
        else
            if grep --color -wq GNU README*; then
                prefix=$HOME/gnu
            else
                prefix=$HOME/local
            fi
        fi
    else
        prefix=$(echo $1 | awk -F'=' '{print$2}')
        prefix=$(echo $prefix | sed 's/~/$HOME/')
        shift
    fi
	configureArgs="--prefix=$prefix --exec-prefix=$prefix $@"
    echo "=> pwd = $PWD"
    echo "=> prefix = $prefix"
    \grep -w url ./.git/config && type -P git > /dev/null 2>&1 && git pull
    if [ ! -s configure ]; then
        test -s ./bootstrap.sh && time ./bootstrap.sh || { 
            test -s ./autogen.sh && time ./autogen.sh
        }
    fi
    if [ ! -s Makefile ]; then
		test -s ./configure && set -x && time ./configure "$configureArgs";set +x
    fi
    local project=$(basename $PWD)
    if [ -d cmake ]; then
        mkdir -p build
        cd build
        if groups | egrep --color -wq "sudo|adm|root"; then
            cmake ..
        else
            cmake .. -DPREFIX=$prefix -DSYSSCONFDIR=$prefix/etc -DSHAREDIR=$prefix/share -DMAN_PATH=$prefix/share/man -DXDG_CONFIG_DIR=$prefix/etc/xdg -DDFC_DOC_PATH=$prefix/share/doc/dfc -DLOCALEDIR=$prefix/share/locale
			cmake .. -DPREFIX=$prefix -DEPREFIX=$prefix
        fi
        returnCode=$?
		grep ":PATH=.*$prefix" CMakeCache.txt
    fi
    if [ -s Makefile ] || [ -s makefile ] || [ -s GNUmakefile ]; then
        if time -p make; then
            returnCode=$?
            \mkdir -p $prefix
            if test -w $prefix; then
                make install
            else
                \sudo make install
            fi
        else
            returnCode=$?
        fi
    else
        returnCode=$?
		printf "=> ERROR: The Makefile could not be generated therefore the building the <$project> source code has failed !\n=> Listing the files :\n$(ls -l)\n" >&2
    fi
    echo "=> returnCode = $returnCode" 1>&2
    return $returnCode
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
		buildSourceCode
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
		buildSourceCode
	fi
}

#main
url=$1
[ "$url" ] || {
	echo "=> ERROR: Usage : $0 <URL>" >&2
	exit 1
}

for url
do
	if echo $url | grep -q github.com
	then
		buildFromGit https://github.com/lvanbever/cbgp
	else
		buildFromArchive http://netix.dl.sourceforge.net/project/libgds/libgds-2.2.2.tar.gz
	fi
done
