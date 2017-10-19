#!/usr/bin/env bash

args=$@
if which matlab >/dev/null
then
#	$(which matlab) -nojvm -r "${args/.m/}; exit" # Incompatible avec fig = gcf; appelle par la fonction surf()
	$(which matlab) -nodesktop -nosplash -r "${args/.m/}; exit"
else
	matlabScript=$1
	shift
	octaveScript=${matlabScript/.m/.octave}
	echo "#!/usr/bin/env octave-cli" > $octaveScript
	egrep -vw "^main|/usr/bin/.*methlabs" $matlabScript >> $octaveScript
	mainFunctionName=$(awk -F "[ (=]" '/function.(\w+ =)?\w+/{print$(NF-3);exit}' $octaveScript)
	echo "$mainFunctionName( argv(){:} )" >> $octaveScript
	chmod +x $octaveScript
	./$octaveScript $@
fi
