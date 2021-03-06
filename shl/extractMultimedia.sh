#!/usr/bin/env ksh

multiMediaFormats="\\.(wav|wma|aac|ac3|mp2|mp3|ogg|m4a|spx|opus|asf|avi|wmv|mpg|mpeg|mp4|divx|flv|mov|ogv|webm|vob|3gp|mkv|m2t|mts|m2ts|asx|m3u|m3u8|pla|pls|smil|vlc|wpl|xspf)"
for url
do
	echo >&2
	echo "=> url = $url"
	echo >&2
#	curl -s $url | tr ";" "\n" | perl -p -e "s/^.*http:/http:/;s/\"$//;s/${multiMediaFormats}\W.*$/.\1\n/i;" | sort -u | egrep -i --color "$multiMediaFormats\>|FOUND"
#	curl -s $url | tr ";" "\n" | perl -n -e "s/^.*http:/http:/;s/\"$//;s/${multiMediaFormats}\W.*$/.\1\n/i;print if /http:.*$multiMediaFormats/i" | sort -u
#	curl -s $url | perl -n -e "s/\;/\n/;s/^.*http:/http:/;s/href=/\nhref=/g;s|href=.|$(dirname $url)/g|;s/\"$//;s/${multiMediaFormats}\W.*$/.\1\n/i;print if /$multiMediaFormats/i" | sort -u
#set -x
	curl -s $url | piconv -t latin9 | tr -d "[\r\f]" | egrep -i --color "$multiMediaFormats\>" | perl -ne "
	s/^.*http:/http:/;								#Supprime tout ce qui precede http:
	s/href=/\nhref=/g;								#Remplace href= par un saut de ligne suivi de href=
	s|href=.|$(dirname $url)/|;							#Supprime tout ce qui precede http:
	s/$multiMediaFormats.*$/.\$1/i;							#Supprime tout ce qui succede a l'extension du fichier multimedia
	s|href=.|$(dirname $url)/|;							#Supprime tout ce qui precede http:
#	print \"Ligne numero \$. : <\$_>\" if /(http|ftp):.*$multiMediaFormats/i;	#Affiche la resultante
	print if /(http|ftp):.*$multiMediaFormats/i;					#Affiche la resultante
" | sort -u
done | perl -ne "s/$multiMediaFormats.*$/.\$1/i;print if /http|ftp/"
