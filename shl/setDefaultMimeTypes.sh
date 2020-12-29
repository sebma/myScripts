#!/usr/bin/env sh

#PDF Documents and others
which evince >/dev/null 2>&1 && {
	documentFileTypes=".pdf"
	documentMimeTypes="$(mimetype -b $documentFileTypes | sort -u | xargs)"
	echo "=> Association des fichiers $documentFileTypes qui s'ouvriront desormais avec <evince>."
	time -p xdg-mime default evince.desktop $documentMimeTypes
	echo "=> Fait."
}

#Ouvrir les fichiers Image avec eog
which eog >/dev/null 2>&1 && {
	imageFileTypes=".gif .ief .jp2 .jpeg .jpg .jpf .pcx .png .svg .svgz .tiff .tif .djvu .djv .ico .wbmp .cr2 .crw .ras .erf .jng .bmp .nef .orf .psd .pnm .pbm .pgm .ppm .rgb .xbm .xpm .xwd"
	imageMimeTypes="$(mimetype -b $imageFileTypes | grep image | sort -u | xargs)"
	echo "=> Association des fichiers $imageFileTypes qui s'ouvriront desormais avec <eog>."
	time -p xdg-mime default eog.desktop $imageMimeTypes
	echo "=> Fait."
}

#Ouvrir les fichiers archives avec File Roller
which file-roller >/dev/null 2>&1 && {
	archiveFileTypes=".bz2 .zip .gz .tgz .xz .rar .lzma"
	archiveMimeTypes="$(mimetype -b $archiveFileTypes | sort -u | xargs)"
	echo "=> Association des fichiers $archiveFileTypes qui s'ouvriront desormais avec <file-roller>..."
	time -p xdg-mime default file-roller.desktop $archiveMimeTypes
	echo "=> Fait."
}

#Ouvrir les fichiers documents avec LibreOffice
which libreoffice >/dev/null 2>&1 && {
	documentFileTypes=".doc .docx .sxw .odt .xls .xlsx .sxc .ods .ppt .pps .pptx .ppsx .sxi .odp .rtf"
	documentMimeTypes="$(mimetype -b $documentFileTypes | sort -u | xargs)"
	echo "=> Association des fichiers $documentFileTypes qui s'ouvriront desormais avec <libreoffice>..."
	time -p xdg-mime default libreoffice-startcenter.desktop $documentMimeTypes
	echo "=> Fait."
}

#Ouvrir la plupart des fichiers Audio avec audacious
which audacious >/dev/null 2>&1 && {
	audioFileTypes=".wav .wma .aac .ac3 .mp2 .mp3 .ogg .oga .opus .m4a"
	audioMimeTypes="$(mimetype -b $audioFileTypes | grep audio | sort -u | xargs) audio/x-vorbis+ogg audio/x-opus+ogg"
	echo "=> Association des fichiers $audioFileTypes qui s'ouvriront desormais avec <audacious>..."
	time -p xdg-mime default audacious.desktop $audioMimeTypes
	echo "=> Fait."
}

#Ouvrir de certains formats audio avec SMPlayer
which smplayer >/dev/null 2>&1 && {
	audioFileTypes=".spx"
	audioMimeTypes="$(mimetype -b $audioFileTypes | grep audio | sort -u | xargs) audio/x-speex+ogg"
	echo "=> Association des fichiers $audioFileTypes qui s'ouvriront desormais avec <smplayer>..."
	time -p xdg-mime default smplayer.desktop $audioMimeTypes
	echo "=> Fait."
}

#Ouvrir les fichiers Video avec SMPlayer
which smplayer >/dev/null 2>&1 && {
	videoFileTypes=".asf .avi .wmv .mpg .mpeg .mp4 .divx .flv .mov .ogv .webm .vob .3gp .mkv .m2t .mts .m2ts"
	videoMimeTypes="$(mimetype -b $videoFileTypes | grep video | sort -u | xargs)"
	echo "=> Association des fichiers $videoFileTypes qui s'ouvriront desormais avec <smplayer>..."
	time -p xdg-mime default smplayer.desktop $videoMimeTypes
	echo "=> Fait."
}

#Ouvrir les fichiers playlist avec SMPlayer
which smplayer >/dev/null 2>&1 && {
#	playlistFileTypes=".asx .bio .fpl .kpl .m3u .m3u8 .pla .aimppl .pls .smil .vlc .wpl .xspf .zpl"
	playlistFileTypes=".asx .m3u .m3u8 .pla .pls .smil .vlc .wpl .xspf"
	playlistMimeTypes="$(mimetype -b $playlistFileTypes | sort -u | xargs)"
	echo "=> Association des fichiers $playlistFileTypes qui s'ouvriront desormais avec <smplayer>..."
	time -p xdg-mime default smplayer.desktop $playlistMimeTypes
	echo "=> Fait."
}

#Association du protocole apt:, ssh: avec les applications adequoites
echo "=> Association du protocole apt:, ssh: avec les applications adequoites ..."
applicationsFolder=/usr/share/applications
xdg-mime default $(command locate $applicationsFolder/*dolphin.desktop | sed "s|$applicationsFolder/||;s|/|-|") inode/directory
xdg-mime default apturl.desktop x-scheme-handler/apt
xdg-mime default putty.desktop x-scheme-handler/ssh
xdg-mime default wine.desktop application/x-ms-dos-executable
echo "=> Fait."
