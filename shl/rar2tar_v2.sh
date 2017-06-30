#!/bin/sh

type 7z &>/dev/null || echo ERREUR: L\'utilitaire \"7z\" est absent du systeme ! 1>&2 && exit 1
type tar &>/dev/null || echo ERREUR: L\'utilitaire \"tar\" est absent du systeme ! 1>&2 && exit 1

UnixDirSep="/"
WindowsDirSep='\\'
uname -a | egrep -iq "linux|sun" && DirSep=$UnixDirSep || DirSep=$WindowsDirSep
#cd ~/Desktop
[ ! -d RAR ] && mkdir RAR
[ ! -d TAR ] && mkdir TAR
[ ! -d $OutputDir ] && mkdir -p $OutputDir

#DecompressCmd="unrar x" && type unrar &>/dev/null || echo ERREUR: L\'utilitaire \"unrar\" est absent du systeme ! 1>&2 && exit 1
DecompressCmd="7z x"

for file in $(ls -1 RAR/*.rar 2>/dev/null)
do
  FileBaseName="$(basename "$file" .rar)"
	declare -i NumberOfDirs=0
	NumberOfDirs=$(7z l -slt $file | grep Path | grep -c "$DirSep")

  OutputDir=/tmp/RAR
	[ "$NumberOfDirs" = "0" ] && OutputDir="/tmp/RAR/$FileBaseName" && mkdir -p "$OutputDir"

	echo "=> Decompressing file $file ..."
	$DecompressCmd "$file" -o"$OutputDir" > /dev/null
  cd /tmp/RAR
	echo "=> Creating the TApe aRchive file ${FileBaseName}.tar ..."
  tar -cvf $OLDPWD/TAR/"${FileBaseName}.tar" * >/dev/null
	rm -fr /tmp/RAR/*
  cd -
	echo ""
done
