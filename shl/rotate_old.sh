#!/usr/bin/env bash

Extension=".JPG"
ExtensionList=".JPG .jpg"

#Pour le shell base sur cygwin
#InputDir="/cygdrive/e/DCIM/100_PANA"
#InputDir="/home/X064304/Bureau/shl"
#OutputDir="/cygdrive/t/PERSO/Mansfeld/Photos_CI"

#Pour le shell base sur MINGW32
#InputDirList="/e/DCIM/[1-9][0-9][0-9]_PANA"
#InputDirList1="/d/Originaux/+90 /d/Originaux/-90"
#OutputDir="/t/PERSO/Mansfeld/Photos_CI"
#OutputDir="/d/Reduites"

Angle1="+90"
InputDirList1="/d/Originaux/+90"
time for Dir in $InputDirList1
do
  #echo "Dir=$Dir"
	OutputDir=$Dir
	for i in "$Dir"/*.JPG
	do
	  FileName=$(basename $i $Extension)
	  echo "-> jpegtran -perfect -rotate $Angle1 $i "$OutputDir"/$FileName.new.jpg ..."
	  jpegtran -perfect -rotate "$Angle1" $i "$OutputDir"/$FileName.new.jpg
		#Restaure le timestamp du fichier stocke dans les etiquettes EXIF de l'image originale
		jhead  -ft "$OutputDir"/$FileName.new.jpg
	done
done

Angle2="270"
InputDirList2="/d/Originaux/-90"
time for Dir in $InputDirList2
do
  #echo "Dir=$Dir"
	OutputDir=$Dir
	for i in "$Dir"/*.JPG
	do
	  FileName=$(basename $i $Extension)
	  echo "-> jpegtran -perfect -rotate $Angle2 $i "$OutputDir"/$FileName.new.jpg ..."
	  jpegtran -perfect -rotate "$Angle2" $i "$OutputDir"/$FileName.new.jpg
		#Restaure le timestamp du fichier stocke dans les etiquettes EXIF de l'image originale
		jhead  -ft "$OutputDir"/$FileName.new.jpg
	done
done

echo
