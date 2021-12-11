#!/usr/bin/env bash

InputDirList="/d/Originaux/+90 /d/Originaux/-90"
time for Dir in $InputDirList
do
	for i in "$Dir"/*.JPG
	do
		#Effectue une rotation automatique de l'image grace l'Orientation stocker dans l'etiquette EXIF et de l'outil "jpegtran"
	  echo "-> jhead -autorot $i ..."
		jhead -ft -autorot $i
		#Restaure le timestamp du fichier stocke dans les etiquettes EXIF de l'image originale
		#jhead -ft $i
	done
done
