#!/usr/bin/env bash

if $(which pip2) freeze | grep -q picoscope || $(which pip3) freeze | grep -q picoscope
then
	if [ $(uname -s) = Darwin ]
	then
		if [ -z $DYLD_LIBRARY_PATH ]
		then
			#Read [Why isn't DYLD_LIBRARY_PATH being propagated here?](https://stackoverflow.com/a/35570229/5649639)
			#Read [System Integrity Protection Guide: Runtime Protections](https://developer.apple.com/library/content/documentation/Security/Conceptual/System_Integrity_Protection_Guide/RuntimeProtections/RuntimeProtections.html)
			test -d /Applications/PicoScope6.app/Contents/Resources/lib && export DYLD_LIBRARY_PATH=/Applications/PicoScope6.app/Contents/Resources/lib
		fi
	elif [ $(uname -s) = Linux ]
	then
		:
	fi
	
	$(which python2) ${0/.sh/.py} $@
else
	for pipCmd in pip2 pip3
	do
		if $(which $pipCmd) freeze | grep -q picoscope
		then
			continue
		else
			echo "=> INFO: Installing the picoscope Python module because it's not installed ..." >&2
			if groups | egrep -wq "sudo|adm|admin"
			then
		#		sudo -H $(which·$pipCmd)·install·picoscope==0.6.2
				sudo -H $(which $pipCmd) install git+https://github.com/colinoflynn/pico-python.git@0.6.2
			else
		#		$(which·$pipCmd)·install·picoscope==0.6.2 --user
				$(which $pipCmd) install git+https://github.com/colinoflynn/pico-python.git@0.6.2 --user
			fi
			echo "=> INFO: Please re-run $0 $@ after that installation." >&2
		fi
	done
fi

