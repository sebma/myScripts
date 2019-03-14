#!sh

function eject {
	groups | grep -q disk && $(which eject) "$@" || sudo $(which eject) "$@"
}
#AUDIO DECODE
function ogg2wavstdout {
	for file
	do
		sox "$file" -t wav -
	done
}
function mp32wavstdout {
	for file
	do
		sox "$file" -t wav -
	done
}
function 2utf8 {
  file=$1
  test $file && recode -v $(file -i $file | cut -d= -f2)..utf8 $file
}
function any2mkv {
  for file
  do
    $(which ffmpeg) -i "$file" -f mkv -vcodec copy -acodec copy "${file%.???}.mkv" || break
  done
}
function any2mp3 {
  for file
  do
    if ffprobe "$file" 2>&1 | grep -q "Audio: mp3"
    then
      $(which ffmpeg) -i "$file" -vn -acodec copy "${file%.???}.mp3" || break
    fi
  done
}
function audioFormat {
  for file
do
  audioFormat=$(ffprobe "$file" 2>&1 | awk '/Audio/{print$4}' | sed "s/,$//")
	if [ $audioFormat = vorbis ]
	then
		format=ogg
	elif [ $audioFormat = aac ]
	then
		format=m4a
	else
		format=$audioFormat
	fi
    echo $format
done
}
function build_in_HOME {
  test -s configure || time ./bootstrap.sh
  test -s Makefile || time ./configure --prefix=$HOME/gnu $@
  test -s Makefile && time make && make install
}
function build_in_usr {
  test -s configure || time ./bootstrap.sh
  test -s Makefile || time ./configure --prefix=/usr $@
  test -s Makefile && time make && sudo make install
}
function containsmp3file {
  for file
  do
    echo
    echo "=> file = $file"
    if ffprobe "$file" 2>&1 | egrep -q "Stream .*Audio.*(mp3)"
    then
      echo "=> File <$file> contains a mp3 stream:"
      ffprobe "$file" 2>&1 | egrep -w "Input|Duration:|Stream"
      true
    else
      echo "=> $file does not contain any mp4 stream."
      false
    fi
  done
}
function containsmp3stream {
  format=best
  echo $1 | grep -q ^http || {
    format=$1
    shift
  }
  echo
  for url
  do
    echo "=> url = $url"
    if \quvi -vm -f $format --exec "ffprobe %u 2>&1" "$url" | egrep -q "Stream .*Audio.*(mp3)"
    then
      echo "=> It contains a mp3 stream."
      echo
    else
      echo "=> $url does not contain any mp3 stream."
      echo
      false
    fi
  done
}
function containsmp4file {
  for file
  do
    echo
    echo "=> file = $file"
    if ffprobe "$file" 2>&1 | egrep -q "Stream .*Video.*(h264)"
    then
      echo "=> File <$file> contains a mp4 stream:"
      ffprobe "$file" 2>&1 | egrep -w "Input|Duration:|Stream"
      true
    else
      echo "=> $file does not contain any mp4 stream."
      false
    fi
  done
}
function containsmp4stream {
  format=best
  echo $1 | grep -q ^http || {
    format=$1
    shift
  }
  echo
  for url
  do
    echo "=> url = $url"
		echo
    if \quvi -vm -f $format --exec "ffprobe %u 2>&1" "$url" | egrep -q "Stream .*Video.*(h264)"
    then
      echo "=> It contains a mp4 stream."
      echo
    else
      echo "=> $url does not contain any mp4 stream."
      echo
      false
    fi
  done
}
function cpio2tgz {
  set -eu
  for file
  do
    dirList=$(cpio -it < $file | cut -d/ -f1 | sort -u)
    cpio -id < $file && tar -c $dirList | gzip -9c > $(basename $file .cpio).tgz && rm -fr $dirList
  done
}
function delExtension {
  firstFile=$1
  extension=$(echo "$firstFile" | awk -F. '{print $NF}')
  rename -v "s/\.$extension$//" *.$extension
}
function ffmpeg {
	test "$1" && $(which ffmpeg) "$@" 2>&1 | egrep -v " lib|enable-"
}
function avprobe {
	for file
	do
		echo "=> File = <$file>" && echo && $(which avprobe) "$file" 2>&1 | egrep -v " lib|enable-"
	done
}
function ffprobe {
	for file
	do
		echo "=> File = <$file>" && echo && $(which ffprobe) "$file" 2>&1 | egrep -v " lib|enable-"
	done
}
function getaudio {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    extension=$(echo "$file" | awk -F. '{print$NF}')
    audioFormat=$(ffprobe "$file" 2>&1 | awk '/Audio/{print$4}' | sed "s/,$//")
	if [ $audioFormat = vorbis ]
	then
		format=ogg
	elif [ $audioFormat = aac ]
	then
		format=m4a
	elif [ $audioFormat = pcm_s16le ]
	then
		format=wav
	else
		format=$audioFormat
	fi
#    format=$(audioFormat "$file")
    output=$musicDir/$(basename "$file" .$extension).$format
    $(which ffmpeg) -i "$file" -vn -acodec copy "$output"
    echo
    test -s "$output" && echo "=> Output file is: <$output>."
  done
}
function get_extension_id {
# Retrieve the extension id for an addon from its install.rdf
	for file
	do
		echo "=> File = $file"
		unzip -qc $file install.rdf | xmlstarlet sel -N rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" -N em="http://www.mozilla.org/2004/em-rdf#" -t -v "//rdf:Description[@about='urn:mozilla:install-manifest']/em:id"
		echo
	done
}
function get_extension_name {
# Retrieve the extension name for an addon from its install.rdf
	for file
	do
		echo "=> File = $file"
		unzip -qc $file install.rdf | xmlstarlet sel -N rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" -N em="http://www.mozilla.org/2004/em-rdf#" -t -v "//rdf:Description[@about='urn:mozilla:install-manifest']/em:name"
		echo
	done
}
function getmp4 {
  for tool in cclive quvi ffprobe
  do
    type $tool >/dev/null || {
      echo "=> ERROR: <$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    echo
    echo "=> url = <$url>"
    fileBaseName="$(\cclive -n $url 2>&1 | egrep "video/|application/octet-stream" | cut -d. -f1).mp4"
    if [ -s "$fileBaseName" ]
    then
      echo "==> <$fileBaseName> is already downloaded."
    else
      if quvi -v mute --exec "ffprobe %u" "$url" 2>&1 | egrep -q "Video: (h264|mp4)"
      then
        echo "==> <$url> contains a mp4 video stream."
        \cclive -c $url --exec "any2mp4 \"%n\""
      else
        echo "==> WARNING: <$url> does not contain any mp4 stream, skipping ..."
      fi
    fi
  done
}
function getmp4 {
  for tool in cclive quvi ffprobe
  do
    type $tool >/dev/null || {
      echo "=> ERROR: <$tool> is not installed." >&2
      return 1
    }
  done
  echo
  for url
  do
    if containsmp4stream $url >/dev/null
    then
      echo "=> <$url> contains a mp4 stream."
      echo
      getxvideos $url >/dev/null
    else
      echo "=> <$url> does not contain any mp4 stream."
      echo
      false
    fi
  done
}
function getRealURL {
  url=$1
  test $# = 2 && format=$2 || format=best
  real_url=$(\quvi -vm -f $format "$url" --exec "echo %u")
  test $real_url && echo "=> real_url = $real_url"
}
function getxvideos {
  for url
  do
    echo "=> url = $url"
    echo
    if echo $url | egrep -q "xvideos.com|www.xvideos"
    then
      videoExtension=$(\quvi -vm --exec "echo %e" $url)
      \cclive -c -O $(basename "$url").$videoExtension "$url"
    else
      \cclive -c "$url"
    fi
  done
}
function locate {
  echo "$@" | grep -q "\-[a-z]*r" && $(which locate) "$@" || $(which locate) -i "*${@}*"
}
function mediainfoSummary {
  for media
  do
    mediainfo "$media" | \egrep "^Complete name|^Format  |^Format version|^Format profile| size|^Duration|^Video|^Audio|Kbps"
    echo
  done
}
function mplayer {
  if tty | grep -q "/dev/pts/[0-9]"
  then
    $(which mplayer) -idx -quiet -geometry 0%:100% "$@" 2>/dev/null | egrep "stream |Track |VIDEO:|AUDIO:|VO:|AO:"
  else
    if [ -c /dev/fb0 ]
    then
      if [ ! -w /dev/fb0 ]
    then
        groups | grep -wq video || sudo adduser $USER video
        sudo chmod g+w /dev/fb0
      fi
      $(which mplayer) -vo fbdev2 -idx -quiet "$@" 2>/dev/null | egrep "stream |Track |VIDEO:|AUDIO:|VO:|AO:"
    else
      echo "=> Function $FUNCNAME - ERROR: Framebuffer is not supported in this configuration." >&2
      return 1
    fi
  fi
}
function pcclive {
  for file
  do
    \cclive -bc $file
    while read line
    do
      \cclive -bc $line
    done < $file
  done
}
function type pkill >/dev/null 2>&1 && pkill {
  arg1=$1
  echo "=> Before :"
  \pgrep -u $USER -lf $arg1
  echo $arg1 | grep -q "\-[0-9A-Z]" && {
    shift
    $(which pkill) $arg1 -f $@
  } || $(which pkill) -f $@
  sleep 1
  echo "=> After :"
  \pgrep -u $USER -lf $arg1
}
function recordRadio {
	$(which mplayer) $1 -dumpaudio -dumpfile radio_$(date +%Y%m%d_%H%M).$(audioFormat $1)
}
function rpm2tgz {
  set -eu
  for file
  do
    cpio_file=$(basename $file .rpm).cpio
    rpm2cpio $file > $cpio_file && \rm -v $file
    cpio2tgz $cpio_file && \rm -v $cpio_file
  done
}
function sizeof {
  local size
  local total="0"
  for url
  do
function     size=$(\quvi -vq -f best --xml $url | xmlstarlet format -R 2>/dev/null | xmlstarlet select -t -v "//length_bytes/text" | awk '{print $0/2^20}')
    total="$total+$size"
    printf "%s %s Mo\n" $url $size
  done
  total=$(echo $total | \bc -l)
  echo "=> total = $total Mo"
}
function type tgz >/dev/null 2>&1 || tgz {
  test $1 && {
    archiveFileName=$1
    shift
    tar -cv $@ | gzip -9 > $archiveFileName
  }
}
function splitaudio {
  if [ $# != 2 ] && [ $# != 3 ]
  then
    echo "=> Usage: $FUNCNAME <filename> hh:mm:ss[.xxx] [ hh:mm:ss[.xxx] ]"
    return 1
  fi

  fileName="$1"
  extension=$(echo $fileName | sed "s/^.*\.//")
  fileBaseName=$(basename "$fileName" .$extension)
  test $extension = m4a && extension=aac
  begin=$2
  if [ $# = 3 ]
  then
    end=$3
    $(which ffmpeg) -i "$fileName" -ss $begin -t $end -vn -acodec copy "$fileBaseName-CUT.$extension"
  else
#   end=$($(which ffmpeg) -i "$fileName" 2>&1 | awk -F",| *" '/Duration:/{print$3}')
    $(which ffmpeg) -i "$fileName" -ss $begin -vn -acodec copy "$fileBaseName-CUT.$extension"
  fi
  test $extension = aac && \mv -v "$fileBaseName-CUT.$extension" "$fileBaseName-CUT.m4a"
}

function splitvideo {
  if [ $# != 2 ] && [ $# != 3 ]
  then
    echo "=> Usage: $FUNCNAME <filename> hh:mm:ss[.xxx] [ hh:mm:ss[.xxx] ]"
    return 1
  fi

  fileName="$1"
  extension=$(echo $fileName | sed "s/^.*\.//")
  fileBaseName=$(basename "$fileName" .$extension)
  begin=$2
  test $# = 3 && {
    end=$3
    $(which ffmpeg) -i "$fileName" -ss $begin -t $end -vcodec copy -acodec copy "$fileBaseName-CUT.$extension"
  } || {
#   end=$($(which ffmpeg) -i "$fileName" 2>&1 | awk -F",| *" '/Duration:/{print$3}')
    $(which ffmpeg) -i "$fileName" -ss $begin -vcodec copy -acodec copy "$fileBaseName-CUT.$extension"
  }
}

function my_wget {
	test $# = 1 && file="$1" || return
	egrep -v "^$|^#" "$file" | while read url filename
	do
		echo "=> Downloading <$filename> at <$url> ..."
		echo
		$(which wget) -c --content-disposition -O "$filename" "$url"
	done
	rename -v 's/\?//g' *
}

function umount {
  for arg
  do
    \fuser -vm $arg/ 2>&1 | grep " $USER " && return
		$(which umount) -vv $arg && echo "=> The <$arg> filesystem is successfully unmounted."
  done
}
function untgz {
  archive="$1"
  echo "=> Uncompression and unarchiving the $archive compressed archive ..."
  gunzip -v $archive || {
    echo "ERROR : The file  $archive is an unvalid gzip  format." >&2
    exit 1
  } 
  tar -tf $(basename $archive .gz) >/dev/null || {
    echo "ERROR : The file  $archive is an unvalid tar archive." >&2
    exit 2
  }
  tar -xvf $(basename $archive .gz)
}
function updatemp4tags {
  for file
  do
    echo "=> file = " $file
    test ! -f "$file" && echo "=> ERROR: File <$file> does not exist." 2>&1 && continue
    AtomicParsley "$file" -t | grep "Atom.*nam.*contains:" && echo "=> ERROR: File <$file> already has the filename metadata." 2>&1 && continue
    fileBase=$(basename "$file")
    freeSpace=$(\df -Pk "$file" | awk '/dev|tmpfs/{print int($4)}')
    fileSize=$(\ls -l "$file" | awk '{print int($5/1024)}')
    if [ $freeSpace -lt $fileSize ]
    then
      \mv -v "$file" /tmp
      AtomicParsley "/tmp/$fileBase" --output "$file" --title "$fileBase"
    else
      AtomicParsley "$file" --overWrite --title "$fileBase"
    fi
    AtomicParsley "$file" -t
  done
}
function vacuum {
#  find . -name "*sqlite" -ls -exec sqlite3 {} vacuum \;
  find . -name "*sqlite" | while read file
  do
#    echo file=$file
    mv $file /tmp/
    echo "=> sqlite3 /tmp/$(basename $file) vacuum; ..."
    sqlite3 /tmp/$(basename $file) 'vacuum;'
    mv /tmp/$(basename $file) $file
  done
}
function videoFormat {
  for file
  do
    videoFormat=$(ffprobe "$file" 2>&1 | awk '/Video/{print$4}' | sed "s/,$//")
    format=$videoFormat
    echo $format
  done
}
function vidinfo {
  for video
  do
    ffprobe "$video" 2>&1 | egrep "Seems|Input|Duration:|Stream|Unknown"
    echo
  done
}
function vidurlinfo {
  format=best
  echo $1 | grep -q ^http || {
    format=$1
    shift
  }
  echo
  for url
  do
    echo "=> url = $url"
    echo
    \quvi -vm -f $format --exec "ffprobe %u 2>&1" "$url" | egrep "Seems|Input|Duration:|Stream|Unknown"
    echo
  sizeof "$url"
  done
}
function wav2mp3 {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .wav).mp3
    lame -v --replaygain-accurate "$file" "$output"
  done
}
function mp32wav {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .mp3).wav
		echo "=> Converting $(basename "$file") to $output ..."
		echo
    mpg123 --wav "$output" "$file"
  done
}
function mp32oggvorbis {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .mp3).ogg
		echo "=> Converting $(basename "$file") to $output ..."
		echo
    mpg123 --wav - "$file" | oggenc -q4 - -o "$output"
  done
}
function mp32oggspeex {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .mp3).spx
		echo "=> Converting $(basename "$file") to $output ..."
		echo
    time sox "$file" -t wav - | speexenc -V --denoise --quality 10 --vbr - "$output"
  done
}
function mp32oggopus {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .mp3).opus
		echo "=> Converting $(basename "$file") to $output ..."
		echo
    sox "$file" -t wav - | opusenc --downmix-mono --bitrate 32 - "$output"
  done
}
function wav2oggvorbis {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .wav).ogg
    oggenc -q4 "$file" -o "$output"
  done
}
function wma2ogg {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .wma)
    bitRate=$($(which ffprobe) "$file" 2>&1 | awk '/Audio:/{print$(NF-1)"k"}')
    $(which ffmpeg) -i "$file" -acodec libvorbis -ab $bitRate "$output".ogg
  done
}
function wma2mp3 {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .wma)
    bitRate=$($(which ffprobe) "$file" 2>&1 | awk '/Audio:/{print$(NF-1)"k"}')
    $(which ffmpeg) -i "$file" -ab $bitRate "$output".mp3
  done
}
function wma2wav {
  echo $LANG | grep -qi fr && musicDir=~/Musique || musicDir=~/Music
  test -d $musicDir || mkdir $musicDir
  for file
  do
    output=$musicDir/$(basename "$file" .wma)
    $(which ffmpeg) -i "$file" "$output".wav
  done
}
function xmlcheck {
  test $# -lt 1 && {
    echo "=> Usage: $FUNCNAME [file1] [file2] ..." >&2
    return 1
  }

  type xmlstarlet >/dev/null 2>&1 && xmlCheckTool="xmlstarlet validate --err" || xmlCheckTool="xml -c"

  for file
  do
    printf "=> $xmlCheckTool $file... "
    $xmlCheckTool $file && echo OK.
  done
}
function xmlindent {
  test $# -lt 1 && {
    echo "=> Usage: $FUNCNAME [file1] [file2] ..." >&2
    return 1
  }

  type xmllint >/dev/null 2>&1 && {
    xmlIndentTool="\xmllint --format"
    encodingOption="--encode"
  } || {
    xmlIndentTool="xml -PP"
    encodingOption="-e"
  }

  for file
  do
    inputFileEncoding=$(awk -F "'|\"" '/xml.*version.*encoding.*=/{print $4;}' $file)
    echo "=> inputFileEncoding = <$inputFileEncoding>" >&2
    test $inputFileEncoding && {
      echo "=> $xmlIndentTool $encodingOption $inputFileEncoding $file ..."
      $xmlIndentTool $encodingOption $inputFileEncoding $file | tee $file.indented
      echo "=> The indented file is <$file.indented>."
    }
  done
}
function xmlvalidate {
  test $# -lt 2 && {
    echo "=> Usage: $FUNCNAME <xsd scheme> [file1] [file2] ..." >&2
    return 1
  }

  type xmllint >/dev/null 2>&1 && xmlValidationTool="xmllint --noout --schema"
  type xmlstarlet >/dev/null 2>&1 && xmlValidationTool="xmlstarlet validate --err --xsd"

  test "$xmlValidationTool" || {
    echo "=> ERROR[Function $FUNCNAME]: There is neither <xmllint> nor <xmlstarlet> installed on <$(hostname)>." >&2
    return 2
  }

  local xsd_scheme=$1
  shift

  for file
  do
    echo "=> $xmlValidationTool $xsd_scheme $file ..."
    $xmlValidationTool $xsd_scheme "$file"
  done
}
function ytgetmp3 {
  echo
  for url
  do
    echo "$url" | grep -q youtube && {
    formatList=$(\quvi -vq -F "$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in $formatList
    do
      echo "=> format = $format"
      containsmp3stream $format "$url" && {
        outputFilename=$(\cclive -cf $format "$url" --exec "echo %f")
        getaudio "$outputFilename" && \rm -v "$outputFilename"
        break
      }
    done
    }
  done
}
function ytgetaac {
  echo
  for url
  do
    echo "$url" | grep -q youtube && {
    formatList=$(\quvi -vq -F "$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in $formatList
    do
      echo "=> format = $format"
      containsmp4stream $format "$url" && {
        outputFilename=$(\cclive -cf $format "$url" --exec "echo %f")
        getaudio "$outputFilename" && \rm -v "$outputFilename"
        break
      }
    done
    }
  done
}
function ytgetmp4 {
  echo
	alreadyDownloaded=false
	typeset -i i=1
  for url
  do
#	  if $alreadyDownloaded
#		then
#		  alreadyDownloaded=false
#			contine
#		fi
    echo "$url" | grep -q youtube && {
		echo "=> Processing url number $i ..."
		echo
    formatList=$(\quvi -vq -F "$url" | grep fmt | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r | xargs)
		test "$formatList" || {
			echo >&2
		  echo "=> ERROR: The URL <$url> could not fetched." >&2
			echo >&2
			let i++
			continue
		}
    for format in $formatList
    do
      echo "=> format = $format"
      containsmp4stream $format "$url" && {
				echo
			  mp4FileBaseName="$(\cclive -f $format -n "$url" 2>&1 | \tail -1 | sed 's/\..*//g').mp4"
			  printf "$url : " >&2
				echo $mp4FileBaseName >&2
				expectedFileSizeMB=0
				expectedFileSizeMB=$(\quvi -f $format "$url" 2>/dev/null | awk -F'"' '/length_bytes/{print int($4/2^20)}')
				echo "=> Taille attendue du fichier : $expectedFileSizeMB Mo"
				realFileSizeMB=0
				test -s "$mp4FileBaseName" && realFileSizeMB=$(wc -c "$mp4FileBaseName" | awk '{print int($1/2^20)}') && echo "=> Taille reelle du fichier : $realFileSizeMB Mo"
				fileSizeDiffMB=$(($expectedFileSizeMB-$realFileSizeMB))
				echo "=> La difference de taille entre le fichier MP4 et le fichier FLV: $fileSizeDiffMB Mo"
				echo
				if [ -s "$mp4FileBaseName" ] && [ $fileSizeDiffMB -le 4 ]
				then
    		  echo "==> <$mp4FileBaseName> is already downloaded, processing next URL ..."
					let i++
					echo;echo
					continue 2
				else
        	outputFilename=$(\cclive -cf $format "$url" --exec "echo %f")
					test "$outputFilename" && any2mp4 "$outputFilename"
					let i++
      	  break
				fi
      }
    done
    }
  done
}
function ytgetogg {
  echo
  for url
  do
    echo "$url" | grep -q youtube && {
    formatList=$(\quvi -vq -F "$url" | cut -d: -f1 | tr "|" "\n" | sort -t_ -k2 -r)
    for format in $formatList
    do
      echo "=> format = $format"
      containsmp3stream $format "$url" && {
        outputFilename=$(\cclive -cf $format "$url" --exec "echo %f")
        getaudio "$outputFilename" && \rm -v "$outputFilename"
        break
      }
    done
    }
  done
}
