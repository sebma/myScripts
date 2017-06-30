#!/bin/sh

i=$1
#CurrFileName=$(jhead -exonly $i | awk '/File name/{print $4}')
Angle=$(jhead -exonly -nofinfo $i | awk '/Orientation/{print $4}')
[ -n "$Angle" ] && {
	echo "Angle=$Angle"
	ExifImageWidth=$(jhead -v $i | awk '/ExifImageWidth/{print$3}')
	ExifImageLength=$(jhead -v $i | awk '/ExifImageLength/{print$3}')
	
	echo "-> jhead -st $(basename ${i} .JPG)-thumb.JPG $i ..."
	jhead -st $(basename ${i} .JPG)-thumb.JPG $i
	echo "-> jpegtran -perfect -rotate $Angle $(basename ${i} .JPG)-thumb.JPG -outfile $(basename ${i} .JPG)-thumb.JPG ..."
	jpegtran -perfect -rotate $Angle $(basename ${i} .JPG)-thumb.JPG -outfile $(basename ${i} .JPG)-thumb.JPG || {
		jpegtran -rotate $Angle $(basename ${i} .JPG)-thumb.JPG -outfile $(basename ${i} .JPG)-thumb.JPG
	}
	#Effectue une rotation automatique de l'image grace l'Orientation stocker dans l'etiquette EXIF et de l'outil "jpegtran"
	echo "-> jhead -ft -autorot $i ..."
	jhead -ft -autorot $i
	echo "-> jhead -ft -rt $(basename ${i} .JPG)-thumb.JPG $i"
	jhead -ft -rt $(basename ${i} .JPG)-thumb.JPG $i
	#Efface le rotation flag de l'EXIF
	echo "-> jhead -ft -norot $i ..."
	jhead -ft -norot $i
	#echo "-> exiv2 -k -M\"set Exif.Thumbnail.Orientation 1\" $i"
	#exiv2 -k -M"set Exif.Thumbnail.Orientation 1" $i
	echo "-> exiv2 -k -M\"set Exif.Photo.PixelXDimension $ExifImageLength\" $i"
	exiv2 -k -M"set Exif.Photo.PixelXDimension $ExifImageLength" $i
	echo "-> exiv2 -k -M\"set Exif.Photo.PixelYDimension $ExifImageWidth\" $i"
	exiv2 -k -M"set Exif.Photo.PixelYDimension $ExifImageWidth" $i
}
