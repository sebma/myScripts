#!/usr/bin/env bash

scriptName=$(basename "$0")
scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
download="$(which wget2 2>/dev/null || which wget 2>/dev/null)"

if test "$download"; then
	download="$download -c"
else
	download="$(which curl) -C- -O"
fi

test "$make" || { which remake >/dev/null && export make="$(which remake) -j$(nproc)" || export make="$(which make) -j$(nproc)"; }

if [ $# != 1 ]; then
	echo "=> Usage: $scriptName <coreutils_version_number>" 1>&2
	exit 1
fi

typeset -r isAdmin=$(groups 2>/dev/null | egrep -wq "sudo|adm|admin|root" && echo true || echo false)
if $isAdmin; then
	prefix=/usr/local
	sudo="command sudo -H"
else
	prefix=$HOME/local
	sudo=""
fi

version=$1
advcpmvGitHubRepo=sebma/advcpmv
$download https://raw.githubusercontent.com/$advcpmvGitHubRepo/master/advcpmv-$version.patch
patch=$(\ls advcpmv-* | grep $version)

if $download http://ftp.gnu.org/gnu/coreutils/coreutils-$version.tar.xz; then
	set -x
	time if tar -xf coreutils-$version.tar.xz; then
		set +x
		cd coreutils-$version
#		mv GNUmakefile GNUmakefile.BACKUP
		\patch -p1 -i ../$patch
		test -s Makefile || time ./configure --prefix=$prefix --exec-prefix=$prefix
		if [ $? = 0 ]; then
			time if $make; then
				if test -x src/cp; then
					cd src
					\cp -puv cp advcp
					\cp -puv mv advmv
					if $sudo install -vpm 755 adv* $prefix/bin/; then
						if cd ../man; then
							\cp -puv cp.1 advcp.1
							\cp -puv mv.1 advmv.1
							\gzip -9v adv*.1
							$sudo install -vpm 644 adv* $prefix/share/man/man1/
						fi
						cd ../..
						rm -fr coreutils-$version* $patch
						rmdir bin
					fi
				fi
			fi
		fi
	fi
fi
