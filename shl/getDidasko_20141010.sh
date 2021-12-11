#!/usr/bin/env bash

function initColors {
	typeset escapeChar=$'\e'
	normal="$escapeChar[m"
	bold="$escapeChar[1m"
	blink="$escapeChar[5m"
	red="$escapeChar[31m"
	green="$escapeChar[32m"
	blue="$escapeChar[34m"
	cyan="$escapeChar[36m"

	yellowOnRed="$escapeChar[33;41m"

	greenOnBlue="$escapeChar[32;44m"
	yellowOnBlue="$escapeChar[33;44m"
	cyanOnBlue="$escapeChar[36;44m"
	whiteOnBlue="$escapeChar[37;44m"

	redOnGrey="$escapeChar[31;47m"
	blueOnGrey="$escapeChar[34;47m"
}

initColors

trap 'echo "$red=> SIGINT Received.$normal";exit;' INT

export TIME="\nreal %E\nuser %U\nsys %S"
time="command time"
fqdn=www.centre-didasko.org
baseUrl=http://$fqdn/audio/page
pageNumberFieldName=page-numbers
typeset -i startPage=1
typeset -i lastPage=1

if [ $# == 0 ]
then
	startPage=1
	startPageName=$(printf "Page%02d.html" $startPage)
	curl -so $startPageName $baseUrl/$startPage
	lastPage=$(basename $(awk -F "'|\"" "/a class=.$pageNumberFieldName.*$fqdn/"'{elem=$4}END{print elem }' $startPageName))
elif [ $# == 1 ]
then
	startPage=$1
	lastPage=$1
fi

echo "=> lastPage = $lastPage"
for i in $(seq $startPage $lastPage)
do
	page=$(printf "Page%02d" $i)
	echo
	echo "$blue=> Page = $page.html$normal"
	if [ ! -s $page.html ]
	then
		if curl -so $page.html $baseUrl/$i
		then
			echo "=> Done."
		else
			echo "=> <$baseUrl/$i> Not found" >&2
			rm $page.html
			continue
		fi
	fi
	if [ -s $page.html ]
	then
		if [ ! -s $page.urls ]
		then
			sed -n "/mp3/s/^.*\(http:[^<>]*mp3\)<.*$/\1/p" $page.html > $page.urls
		fi
		while read url
		do
			echo
			echo "$cyan==> url = $url$normal"
			ext=$(echo $url | sed "s/.*\(...\)$/\1/")
			baseName=$(basename $url)
			originalSize=$(curl -sI $url 2>&1 | tr -d "\r" | awk -F ": " '/HTTP.*200.OK/{found=1;size=0}found==1&&/Content-Length/{size=$2}END{print size}')
			echo "==> baseName = $baseName, originalSize = <$originalSize>$normal"
			if [ -f $baseName ]
			then
				fileSize=$(stat -c %s $baseName)
			else
				fileSize=0
			fi
#			echo "==>     fileSize = <$fileSize>"
			if [ $fileSize != $originalSize ]
			then
				echo "$red==> The sizes differ, downloading the rest of <$baseName> file ..."
				$time curl -C- -O $url
				echo $normal
				echo "==> returnCode = $?"
			fi
			if [ -s $baseName ]
			then
				outputFile=$(basename $url .$ext).oga
				if [ ! -s $outputFile ]
				then
					echo $green
					sox $baseName -r 16k -t wav - | $time speexenc -V --quality 10 --vbr - $outputFile
					echo $normal
					echo
				fi
			fi
		done < $page.urls
	fi
done

trap - INT
