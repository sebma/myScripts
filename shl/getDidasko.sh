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

trap 'echo "$red=> SIGINT Received.$normal";test -f .timestamp && rm .timestamp;exit;' INT

export TIME="\nreal %E\nuser %U\nsys %S"
time="$(which time) -p"
fqdn=www.centre-didasko.org
baseUrl=http://$fqdn/audio/page
pageNumberFieldName=page-numbers
typeset -i startPage=1
typeset -i lastPage=1

if [ $# == 0 ]
then
	startPage=1
	startPageFileName=$(printf "Page%02d.html" $startPage)
	echo "=> Counting the total number of pages ..."
	curl -Rso $startPageFileName $baseUrl/$startPage
#	lastPage=$(basename $(awk -F "'|\"" "/a class=.$pageNumberFieldName.*$fqdn/"'{elem=$4}END{print elem }' $startPageFileName))
	xmlstarlet format --html --recover --indent-tab $startPageFileName > ${startPageFileName/.*/.xml} 2>/dev/null
	lastPage=$(xpath -q -e "//li/a[@class='$pageNumberFieldName']/text()" ${startPageFileName/.*/.xml} 2>/dev/null | tail -1)
	echo "=> lastPage = <$lastPage>."
	echo "=> Done."
elif [ $# == 1 ]
then
	startPage=$1
	lastPage=$1
elif [ $# == 2 ]
then
	startPage=$1
	lastPage=$2
fi

album="Centre Didasko"

standard_encoding=utf8
echo "=> startPage = $startPage"
echo "=> lastPage = $lastPage"

function mp32spx {
	typeset titleFileName="$1"
	if [ -s "$titleFileName" ]
	then
		title=$(mp3info -p %t "$titleFileName")
		echo "==> title = <$title>"
		album=$(mp3info -p %l "$titleFileName")
		echo "==> album = <$album>"
#		artist=$(mp3info -p %a "$titleFileName")

		outputFile=${titleFileName/.mp3/.oga}
		echo "==> outputFile = $outputFile"
		if [ ! -s "$outputFile" ]
		then
			printf "$green"
			namedPipe=$(mktemp -u --suffix=.wav)
			mkfifo $namedPipe
			sox "$titleFileName" -r 16k -t wav $namedPipe norm &
			$time speexenc --title "$title" --comment ALBUM="$album" -V --quality 10 --vbr $namedPipe "$outputFile"
			\rm $namedPipe
		fi
	fi
}

for i in $(seq $startPage $lastPage)
do
	page=$(printf "Page%02d" $i)
	echo
	echo "$blue=> Page = $page.html$normal"

	if [ ! -s $page.html ]
	then
		if curl -Rso $page.html $baseUrl/$i
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
		xmlstarlet format --html --recover --indent-tab $page.html > $page.xml 2>/dev/null
		if [ ! -s $page.urls ]
		then
			sed -n "/mp3/s/^.*\(http:[^<>]*mp3\)<.*$/\1/p" $page.html > $page.urls
		fi
		j=1

		while read url
		do
			echo
			echo "$cyan==> url = $url$normal"
			ext=$(echo $url | sed "s/.*\(...\)$/\1/")
			baseFileName=$(basename $url)
			title=$(xpath -q -e "//div[@class='single-post'][$j]/div/h3/a/text()" $page.xml 2>/dev/null | sed "s/\.$//")
			echo "==> title = <$title>"
			encoding=$(echo $title | file -bi - | cut -d= -f2)
			echo "==> encoding = <$encoding>"
			title=$(echo $title | iconv -f $encoding -t $standard_encoding)
			echo "==> title = <$title>"
			titleFileName=$title.mp3
			echo "==> titleFileName = <$titleFileName>"
			echo "==> Getting originalFileSize from the website ..."
			originalFileSize=$(curl -sI $url 2>&1 | tr -d "\r" | awk -F ": " '/HTTP.*200.OK/{found=1;size=0}found==1&&/Content-Length/{size=$2}END{print size}')
			if [ -f "$titleFileName" ]
			then
				fileSize=$(stat -c %s "$titleFileName")
			else
				fileSize=0
			fi

			test $originalFileSize || {
				echo "$red==> ERROR: The size of the file to download is 0, continuing to the next file ...$normal"
				continue
			}

			if [ $fileSize -lt $originalFileSize ]
			then
				echo "==> titleFileName = $titleFileName, fileSize = <$fileSize>, originalFileSize = <$originalFileSize>$normal"
				echo "$blue==> The sizes differ, downloading the rest of <$titleFileName> file ..."
				$time curl -RC- -o "$titleFileName" $url
				touch -r "$titleFileName" .timestamp
				echo $normal
				id3tag -s "$title" -A "$album" "$titleFileName"
				touch -r .timestamp "$titleFileName"
				echo "==> returnCode = $?"
			fi

			mp32spx "$titleFileName"
			echo $normal
			let j++
		done < $page.urls
	fi
done

trap - INT
test -f .timestamp && rm .timestamp
