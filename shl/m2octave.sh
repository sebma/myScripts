#!/usr/bin/env bash

if [ $(uname -s) = Darwin ]
then
	octaveShebang='#!'"$(which env) octave-cli"
elif [ $(uname -s) = Linux ]
then
	octaveShebang='#!'"$(which env) octave-cli"
fi

for matlabScript
do
	octaveScript=${matlabScript/.m/.octave}
	if test -s $octaveScript
	then
		test -w $octaveScript || {
			echo "=> $0 ERROR : <$octaveScript> is readonly." >&2
			continue
		}
	fi

	printf "$octaveShebang" > $octaveScript
	test $(uname) = Darwin && egrep -wq "surf|plot" $matlabScript && echo " --persist" >> $octaveScript || echo >> $octaveScript

	egrep -vw "^main|/usr/bin/.*methlabs" $matlabScript >> $octaveScript
	mainFunctionName=$(awk -F "[ (=]" '/function.(\w+ =)?\w+/{print$(NF-3);exit}' $octaveScript)
	echo "$mainFunctionName( argv(){:} )" >> $octaveScript
	chmod +x $octaveScript
done
