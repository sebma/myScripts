#!/usr/bin/env bash

for file
do
	echo "#!/usr/bin/env octave-cli" > ${file/.m/.octave}
	egrep -vw "^main|/usr/bin/.*methlabs" ${file} >> ${file/.m/.octave}
	echo main >> ${file/.m/.octave}
	chmod +x ${file/.m/.octave}
done
