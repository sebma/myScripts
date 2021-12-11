#!/usr/bin/env bash

Extension=".JPG"
ExtensionList=".JPG .jpg"

#Pour le shell base sur cygwin
#InputDir="/cygdrive/e/DCIM/100_PANA"
#InputDir="/home/X064304/Bureau/shl"
#OutputDir="/cygdrive/t/PERSO/Mansfeld/Photos_CI"

#Pour le shell base sur MINGW32
#InputDirList="/e/DCIM/[1-9][0-9][0-9]_PANA"
InputDirList="/d/Originaux"
#OutputDir="/t/PERSO/Mansfeld/Photos_CI"
OutputDir="/d/Compressees"

#declare -i Quality=98
#Ratio="50%"
declare -i Quality=86

time for Dir in $InputDirList
do
  #echo "Dir=$Dir"
	for i in "$Dir"/*.JPG
	do
	  FileName=$(basename $i $Extension)
	  #echo "-> convert -resize $Ratio -quality $Quality $i "$OutputDir"/$FileName.new.jpg ..."
	  #convert -resize $Ratio -quality $Quality $i "$OutputDir"/$FileName.new.jpg
	  echo "-> convert -quality $Quality $i "$OutputDir"/$FileName.new.jpg ..."
	  convert -quality $Quality $i "$OutputDir"/$FileName.new.jpg
		#Restaure le timestamp du fichier stocke dans les etiquettes EXIF de l'image originale
		jhead -ft "$OutputDir"/$FileName.new.jpg
	done
done

