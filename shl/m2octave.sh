#!/usr/bin/env bash

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
	echo "#!/usr/bin/env octave-cli" > $octaveScript
	egrep -vw "^main|/usr/bin/.*methlabs" $matlabScript >> $octaveScript
	mainFunctionName=$(awk -F "[ (=]" '/function.(\w+ =)?\w+/{print$(NF-3);exit}' $octaveScript)
	echo "$mainFunctionName( argv(){:} )" >> $octaveScript
	chmod +x $octaveScript
done
