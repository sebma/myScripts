#!/usr/bin/env bash

for matlabScript
do
	octaveScript=${matlabScript/.m/.octave}
	echo "#!/usr/bin/env octave-cli" > $octaveScript
	egrep -vw "^main|/usr/bin/.*methlabs" $matlabScript >> $octaveScript
	mainFunctionName=$(awk -F "[ (=]" '/function.(\w+ =)?\w+/{print$(NF-3);exit}' $octaveScript)
	echo "$mainFunctionName( argv(){:} )" >> $octaveScript
	chmod +x $octaveScript
done
