#!/usr/bin/env bash

if [ $# -ge 1 ] && echo $@ | grep -wq "\-h"
then
	echo "=> Usage: $0 [picoscopeLIB_DIR]" >&2
	exit
fi

if [ $# = 1 ] && ! test -d $1
then
	echo "=> $0 ERROR: The directory <$1> does not exist." >&2
	exit 1
fi

if [ $(uname -s) = Darwin ]
then
	test $# -ne 0 && picoscopeLIB_DIR=$1 || picoscopeLIB_DIR=/Applications/PicoScope6.app/Contents/Resources/lib
	if [ -z $DYLD_LIBRARY_PATH ]
	then
		#Read [Why isn't DYLD_LIBRARY_PATH being propagated here?](https://stackoverflow.com/a/35570229/5649639)
		#Read [System Integrity Protection Guide: Runtime Protections](https://developer.apple.com/library/content/documentation/Security/Conceptual/System_Integrity_Protection_Guide/RuntimeProtections/RuntimeProtections.html)
		test -d $picoscopeLIB_DIR && export DYLD_LIBRARY_PATH=$picoscopeLIB_DIR
	fi

	test -s ~/.profile  && grep -wq DYLD_LIBRARY_PATH= ~/.profile  || echo export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH >> ~/.profile
	test -s ~/.zprofile && grep -wq DYLD_LIBRARY_PATH= ~/.zprofile || echo export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH >> ~/.zprofile
	sudo update_dyld_shared_cache
elif [ $(uname -s) = Linux ]
then
	test $# -ne 0 && picoscopeLIB_DIR=$1 || picoscopeLIB_DIR=/opt/picoscope/lib
	if [ -z $LD_LIBRARY_PATH ]
	then
		test -d $picoscopeLIB_DIR && export LD_LIBRARY_PATH=$picoscopeLIB_DIR
	fi

	test -s ~/.profile  && grep -wq LD_LIBRARY_PATH= ~/.profile  || echo export LD_LIBRARY_PATH=$LD_LIBRARY_PATH >> ~/.profile
	test -s ~/.zprofile && grep -wq LD_LIBRARY_PATH= ~/.zprofile || echo export LD_LIBRARY_PATH=$LD_LIBRARY_PATH >> ~/.zprofile
	test -d $LD_LIBRARY_PATH && echo $LD_LIBRARY_PATH | sudo tee -a /etc/ld.so.conf.d/picoscope.conf
	sudo ldconfig
fi
