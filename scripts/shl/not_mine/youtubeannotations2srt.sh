#!/bin/bash
#
# Convert the youtube annotation into SRT subtitle
#
# By Shang-Feng Yang <storm_dot_sfyang_at_gmail_dot_com>
# updated by Sven Fischer <git-dev_ät_linux4tw_dot_de>
#
# Version: 0.2
# License: GPL v3

# for printf to work:
LC_NUMERIC=C LC_COLLATE=C

function usage() {
  echo -e "Usage:\n"
  echo -e "\t$(basename $0) ANNOTATION_FILE\n"
}

function parseXML() {
  # remove all linebreaks
  sed ':a;N;$!ba;s/\n/ /g' ${ANN} > ${ANN}.sed
  # replace anchoredRegion tags with rects
  sed 's/anchoredRegion/rectRegion/g' ${ANN}.sed > ${ANN}.sed2
  mv ${ANN}.sed2 ${ANN}.sed
  cat ${ANN}.sed | xmlstarlet sel -t -m 'document/annotations/annotation' -v 'TEXT' -o '#' -m 'segment/movingRegion/rectRegion' -v '@t' -o '#' -b -n
}

function reformatTime() {
  H=$(echo $1 | cut -d ':' -f 1)
  H=$((10#$H)) #Fixes printf: 09: invalid octal number
  M=$(echo $1 | cut -d ':' -f 2)
  M=$((10#$M)) #Fixes printf: 09: invalid octal number
  S=$(echo $1 | cut -d ':' -f 3)
  printf '%02d:%02d:%02.3f' ${H} ${M} ${S} |tr '.' ','
}

ANN=$1
SRT=$(basename ${ANN} .xml).srt
IFS=$'\n'
I=0

[ -f ${ANN} ] || { usage; exit 1; }
[ -f ${SRT} ] && rm ${SRT}

for LINE in $(parseXML); do
  (( I++ ))
  C=$(echo ${LINE} | cut -d '#' -f 1)
  B=$(echo ${LINE} | cut -d '#' -f 2)
  E=$(echo ${LINE} | cut -d '#' -f 3)
  echo -e "${I}\n$(reformatTime ${B}) --> $(reformatTime ${E})\n${C}\n" >> ${SRT}
done

rm ${ANN}.sed

