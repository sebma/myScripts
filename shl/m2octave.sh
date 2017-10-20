#!/usr/bin/env bash

[ $(uname -s) = Darwin ] && octaveShebang='#!'"$(which env) octave-cli -q"
[ $(uname -s) = Linux ]  && octaveShebang='#!'"$(which octave-cli)"

matlab2D_3D_PlottingFunctions="animatedline|area|bar|bar3|bar3h|barh|comet|comet3|compass|coneplot|contour|contour3|contourf|contourslice|errorbar|ezpolar|fcontour|feather|fimplicit|fimplicit3|fmesh|fplot|fplot3|fsurf|heatmap|histogram|histogram2|image|imagesc|loglog|mesh|meshc|meshz|pareto|pcolor|pie|pie3|plot|plot3|plotmatrix|polarhistogram|polarplot|polarscatter|quiver|quiver3|ribbon|scatter|scatter3|semilogx|semilogy|slice|spy|stairs|stem|stem3|streamline|streamparticles|streamribbon|streamslice|streamtube|surf|surfc|surfl|waterfall"

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
	egrep -wq "$matlab2D_3D_PlottingFunctions" $matlabScript && echo " --persist" >> $octaveScript || echo >> $octaveScript

	egrep -vw "^main|/usr/bin/.*methlabs" $matlabScript >> $octaveScript
	mainFunctionName=$(awk -F "[ (=]" '/function.(\w+ =)?\w+/{print$(NF-3);exit}' $octaveScript)
	echo "$mainFunctionName( argv(){:} )" >> $octaveScript
	chmod +x $octaveScript
done
