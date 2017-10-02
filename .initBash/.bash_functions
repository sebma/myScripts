#!/usr/bin/env bash
#VARIABLES GLOBALES

#echo "=> BASH_SOURCE[0] = ${BASH_SOURCE[0]}"

test -r $initDir/.colors && source $initDir/.colors
test -r $initDir/.AV_functions && source $initDir/.AV_functions
test -r $initDir/.youtube_functions && source $initDir/.youtube_functions

function odf2 {
	test $# -lt 2 && {
		echo "=> Usage: $BASH_FUNC pdf|doc|docx|ppt|pptx|xls|xlsx file1 [file2] [file3] ..." >&2
		return 1
	}
	format=$1
	shift
	for files
	do
		echo "$(which loffice) --headless --convert-to $format $file ..."
		$(which loffice) --headless --convert-to $format $file
	done
}
function brewInstall {
	case $(uname) in 
		Darwin)
			command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
			set -x
			$(which brew) update
			$(which brew) tap caskroom/cask
			$(which brew) tap caskroom/versions;set +x ;;
		Linux)
			command -v brew >/dev/null || $(which ruby) -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
			$(which brew) update ;;
		*) echo "=> ERROR : brew does not support $(uname)." >&2; exit 1;;
	esac
}
function make {
	if [ -s Makefile ] || [ -s makefile ]
	then
		CFLAGS=-g $(which make) $@
	else
		\mkdir ../bin 2>/dev/null
		if which gcc >/dev/null 2>&1
		then
			for file
			do
				echo $(which gcc) -ggdb $file.c -o ../bin/$file
				$(which gcc) -ggdb $file.c -o ../bin/$file
			done
		else
			for file
			do
				echo $(which cc) -g $file.c -o ../bin/$file
				$(which cc) -g $file.c -o ../bin/$file
			done
		fi
	fi
}
function gitUpdateAllLocalRepos {
	local dir=""
	$(which gfind) ~ -type d -name .git | while read dir
	do
		cd $dir/..
		echo "=> Updating <$dir> local repo. ..." >&2
		\grep -w url ./.git/config && \git pull
		cd - >/dev/null
	done
	unset dir
}
function env {
	$(which env) $@ | sort
}
function os {
	case $(uname -s) in
	Darwin) sw_vers >/dev/null 2>&1 && echo $(sw_vers -productName) $(sw_vers -productVersion) || system_profiler SPSoftwareDataType || defaults read /System/Library/CoreServices/SystemVersion ProductVersion ;;
	Linux) lsb_release -sd  2>/dev/null || awk -F'[="]' '/PRETTY_NAME/{print$(NF-1)}' /etc/os-release || sed -n 's/\\[nl]//g;1p' /etc/issue ;;
	*) ;;
	esac
}
function findLoops {
	$(which find) . -follow 2>&1 >/dev/null | egrep -w "loop|denied"
}
function dirName {
	#NE MARCHE PAS LORSQUE LE CHEMIN NE CONTIENT PAS DE "/"
	for arg
	do
		echo ${arg%/*}
	done
}
function baseName {
	for arg
	do
		echo ${arg/*\//}
	done
}
function speedTest {
	type iperf3 >/dev/null || return
	for iperf3PublicServer in bouygues.testdebit.info ping.online.net ikoula.testdebit.info debit.k-net.fr speedtest.serverius.net iperf.eenet.ee iperf.volia.net
	do
		echo "=> Connecting to IPerf server $iperf3PublicServer ..." >&2
		time iperf3 -c $iperf3PublicServer && break
	done
}
function nbPages {
	for file
	do
		printf "$file:Pages: "
		pdfinfo $file | awk '/Pages:/{print$NF}'
	done | awk '/Pages:/{nbPages+=$NF;print}END{print "=> Total: " nbPages}'
}
function lprPageRange {
	pageRange=$1
	shift
	test $pageRange && echo $pageRange | grep -ivq "[A-Z]" && $(which lpr) -o page-ranges=$pageRange $@ && lpq
}
function lprColorPageRange {
	colorPrinter="$(lpstat -a | awk '/[Cc](olor|ouleur)/{prt=$1;exit}END{print prt}')"
	test $colorPrinter && lprPageRange $@ -P $colorPrinter
}
function getFiles {
	test $# -lt 2 && {
		echo "=> Usage: $FUNCNAME <wget args> URL" >&2
		return 1
	}

	lastArg="$(eval echo \$$#)"
	url=$lastArg
	echo $url | \egrep "^(https?|ftp)://" || {
		echo "=> ERROR: This protocol is not supported by GNU Wget." >&2
		return 2
	}
	baseUrl=$(echo $url | awk -F/ '{print$3}')
	$(which wget) --no-parent --continue --timestamping --random-wait --user-agent=Mozilla --content-disposition --convert-links --page-requisites --recursive --reject index.html --accept "$@"
}
function ssh {
	local reachable=""
	local sshOptions="-A -Y -C"
	type ssh >/dev/null || return
	remoteSSHServer=$(echo $@ | awk '{sub("^(-[[:alnum:]_]+ )+","");sub("[[:alnum:]_]+@","");print$1}')
	if which netcat >/dev/null 2>&1
	then
		netcat -v -z -w 5 $remoteSSHServer 22 2>&1 | egrep -v "succeeded|open" || $(which ssh) $sshOptions $@
	else
		$(which bash) -c ": < /dev/tcp/$remoteSSHServer/ssh" && $(which ssh) $sshOptions $@
	fi
}
function aria2c {
	for url
	do
		$(which aria2c) "$url"
	done
}
function systemType {
	if which lsb_release >/dev/null
	then
		system=$(lsb_release -si)
	else
		system=$OSTYPE
	fi
	echo $system
}
function installDate {
	system=$(systemType)
	case $system in
		Debian|Ubuntu) \ls -lact --full-time /etc | awk 'END {print $6,substr($7,1,8)}' ;;
		Mer|Redhat) \rpm -q basesystem --qf '%{installtime:date}\n' ;;
		darwin15*) \ls -lactL -T /etc | awk 'END {print $6,$7,$8}' ;;
	*)	;;
	esac
}
function whereisIP {
	which curl >/dev/null && \curl -A "" ipinfo.io/$1 || \wget -qO- -U "" ipinfo.io/$1
}
function pip {
	local caller=${FUNCNAME[1]}
	test $caller || caller="pip"
	which $caller >/dev/null || { echo "$0: ERROR $caller is not installed">&2;return 1; }
	firstArg=$1
	if   [ "$firstArg" = install ] && [ $(uname -s) = Linux ]
	then
		if groups | egrep -wq "sudo|admin"
		then
			\sudo -H $(which $caller) $@
		else
			$(which $caller) $@ --user
		fi
	elif [ "$firstArg" = uninstall ] && [ $(uname -s) = Linux ]
	then
		if groups | egrep -wq "sudo|admin"
		then
			\sudo -H $(which $caller) $@ 
		else
			$(which $caller) $@
		fi
	else
		$(which $caller) $@
	fi
}
function pip2 {
	which pip2 >/dev/null || { echo "-$0: pip2: command not found">&2;return 1; }
	pip $@
}
function pip3 {
	which pip3 >/dev/null || { echo "-$0: pip3: command not found">&2;return 1; }
	pip $@
}
function conda2Rename {
	oldName=$1
	newName=$2
	test $# = 2 && {
		conda2 create --name $newName --offline --clone $oldName
		conda2 remove --name $oldName --offline --all
	}
}
function conda3Rename {
	oldName=$1
	newName=$2
	test $# = 2 && {
		conda3 create --name $newName --offline --clone $oldName
		conda3 remove --name $oldName --offline --all
	}
}
function gitCloneNonEmptyDir {
	local url="$1"
	local dir="$2"
	test $dir || dir=.
	test $url && {
		git init "$dir"
		git remote | grep -q origin || git remote add origin "$url"
		git fetch
		git pull origin master
		git branch --set-upstream-to=origin/master master
	}
}
function gitCloneHome {
	test $# -ge 1 && gitCloneNonEmptyDir $@ $HOME
}
function configure {
	test $CC || export CC=$(echo $HOSTTYPE-$OSTYPE-gcc | sed "s/armv[^-]*-/arm-/")
	local defaultBuildOptions="--enable-shared"
	local project=$(basename $PWD)
	local returnCode=0
	test "$1" = "-h" && {
		echo "=> Usage: $FUNCNAME [--prefix=/installation/path] [./configure arguments ...]" >&2
		return 1
	}
	if [ $# = 0 ] || ! \egrep -q "\--prefix=[0-9a-zA-Z_/]+" <<< "$@"
	then
		if groups | \egrep -wq "sudo|adm|root"
		then
			prefix=/usr/local
		elif grep -wq GNU README* COPYING
		then
			prefix=$HOME/gnu
		else
			prefix=$HOME/local
		fi
	else
		prefix=$(echo $1 | awk -F'=' '{print$2}')
		prefix=$(echo $prefix | sed 's/~/$HOME/') #Configure ne supporte parfois pas les chemins contenant '~'
		shift
	fi
	configureArgs="--prefix=$prefix --exec-prefix=$prefix $defaultBuildOptions $@"
	echo "=> pwd = $PWD"
	echo "=> prefix = $prefix"
	\grep -w url ./.git/config && which git >/dev/null 2>&1 && git pull
	if [ -d cmake ]
	then
		mkdir -p build
		cd build
		if groups | \egrep -wq "sudo|adm|root" && grep -q /usr <<< $prefix
		then
			unset CC
			cmake .. $@
			returnCode=$?
		else
			unset CC
			cmake .. -DPREFIX=$prefix -DEPREFIX=$prefix $@
			returnCode=$?
		fi
		returnCode=$?
		grep ":PATH=.*$prefix" CMakeCache.txt
		cd -
	else
		if [ ! -s configure ]
		then
#			test -s ./bootstrap.sh && time ./bootstrap.sh || { test -s ./bootstrap && time ./bootstrap || test -s ./autogen.sh && time ./autogen.sh; }
			for autoconfProg in bootstrap.sh bootstrap autogen.sh
			do	
				test -s $autoconfProg && set -x && time ./$autoconfProg $configureArgs && break
			done
			test $? != 0 && set -x && autoreconf -vi
			returnCode=$?
			set +x
		fi
		if [ ! -s Makefile ]
		then
			test -s ./configure && set -x && time ./configure $configureArgs
			returnCode=$?;set +x
		fi
	fi
	echo "=> returnCode = $returnCode" >&2
	return $returnCode
}
function buildSourceCode {
	test $CC || export CC=$(echo $HOSTTYPE-$OSTYPE-gcc | sed "s/armv[^-]*-/arm-/")
	local defaultBuildOptions=""
	local returnCode=0
	local project=$(basename $PWD)
	configure $defaultBuildOptions "$@"
	returnCode=$?

	if [ $returnCode = 0 ] && ( [ -s Makefile ] || [ -s makefile ] || [ -s GNUmakefile ] )
	then
		if time -p make
		then
			returnCode=$?
			\mkdir -p $prefix
			if test -w $prefix
			then
				make install
				returnCode=$?
			else
				sudo make install
				returnCode=$?
			fi
		else
			returnCode=$?
		fi
	else
		returnCode=$?
		printf "=> ERROR: The Makefile could not be generated therefore the building the <$project> source code has failed !\n=> Listing the files :\n$(ls -l)\n" >&2
	fi

	unset CC
	echo "=> returnCode = $returnCode" >&2
	return $returnCode
}
function buildSourceCodeForAndroid {
	local dest=arm-linux-androideabi
	test $CC || export CC=$dest-gcc
	local defaultBuildOptions="--prefix=$HOME/build/android --host=$dest --build=$MACHTYPE"
	local returnCode=0
	buildSourceCode $defaultBuildOptions "$@"
	return $?
}
function configureForAndroid {
	local dest=arm-linux-androideabi
	test $CC || export CC=$dest-gcc
	local defaultBuildOptions="--prefix=$HOME/build/android --host=$dest --build=$MACHTYPE"
	local returnCode=0
	configure $defaultBuildOptions "$@"
	return $?
}
function buildSourceCodeForJolla {
	local dest=arm-linux-gnueabihf
	test $CC || export CC=$dest-gcc
	local defaultBuildOptions="--prefix=$HOME/build/jolla --host=$dest"
	local returnCode=0
	buildSourceCode $defaultBuildOptions "$@"
	return $?
}
function configureForJolla {
	local dest=arm-linux-gnueabihf
	test $CC || export CC=$dest-gcc
	local defaultBuildOptions="--prefix=$HOME/build/jolla --host=$dest"
	local returnCode=0
	configure $defaultBuildOptions "$@"
	return $?
}
function tcpConnetTest {
    time \netcat -v -z -w 5 $(echo $@ | tr ":" " ")
}
function addKeys {
	for key
	do
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
	done
}
function downgradePackages {
	for package
	do
		previousVersion=$(apt-cache show $package | grep Version | sed -n '2p' | cut -d' ' -f2)
		sudo $(which apt) install -V $package=$previousVersion
	done
}
function ldapUserFind {
	if which ldapsearch >/dev/null 2>&1
	then
		ldapsearch -x -LLL uid=$1
	fi
}
function pdfConcat {
	test $1 && {
		args=$@
		lastArg="$(eval echo \$$#)"
		allArgsButLast="${@:1:$#-1}"
#		which pdftk >/dev/null 2>&1 && $allArgsButLast cat output $lastArg || pdfjoin --rotateoversize false $allArgsButLast -o $lastArg
		gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$lastArg $allArgsButLast && open $lastArg
	}
}
function processUsage {
	local columns="rssize,pmem,pcpu,pid,args"
#	headers=$(\ps -e -o $columns | grep -v grep.*COMMAND | \grep COMMAND)
	headers=" RSS\t       %MEM %CPU  PID   COMMAND"
	echo -e "$headers" >&2
	\ps -e -o $columns | sort -nr | cut -c-156 | head -500 | awk '!/COMMAND/{printf "%9.3lf MiB %4.1f%% %4.1f%% %5d %s\n", $1/1024,$2,$3,$4,$5}' | head -45
}
function memUsage {
	LANG=C
	local processName=$1
	local columns="pid,comm,pmem,rssize"
	if test $processName
	then
		\pgrep -f $processName >/dev/null && \ps -o $columns -p $(\pgrep -f $processName) | awk '/PID/;/[0-9]/{sub($4,$4/1024);print$0" MiB";total+=$4}END{if(total>1024)printf "=> Total= %.3lf GiB\n\n",total/1024>"/dev/stderr"; else printf "=> Total= %.3f MiB\n\n",total>"/dev/stderr"}' | \column -t
	else
#		\ps -eo rss= | awk '/[0-9]/{total+=$1/1024}END{print "\tTotal= "total" MiB"}'
		\free -m | awk '/Mem:/{total=$2}/buffers.cache:/{used=$3}END{printf "%5.2lf%%\n", 100*used/total}'
	fi
}
function open {
	[ $(uname -s) = Linux ]  && openCommand=$(which xdg-open)
	[ $(uname -s) = Darwin ] && openCommand=$(which open)
	for file
	do
		$openCommand "$file" 2>&1 | egrep -v "MBuntu-Y-For-Unity"
	done
}
function distribType {
	local distribType=unknown
	if which lsb_release >/dev/null 2>&1
	then
		case $(lsb_release -si) in
			Ubuntu|Debian) distribType="debian";;
			Mer |Redhat|Fedora) distribType="redhat";;
			*) distribType=unknown;;
		esac
	else
		if   [ $(uname -s) = Linux ]
		then
			distribType=$(awk -F"=" '/^(ID|ID_LIKE)=/{last=$2}END{print last}' /etc/os-release)
		elif [ $(uname -s) = Darwin ]
		then
			distribType="$(sw_vers -productName)"
		else
			distribType=unknown
		fi

	fi
	echo $distribType
}
function distribPackageMgmt {
	case $(distribType) in
		debian|Debian) packageType="deb";;
		redhat|Redhat|sailfishos) packageType="rpm";;
		*) packageType=unknown;;
	esac
	echo $packageType
}
function whatPackageContainsExecutable {
	for executable
	do
		case "$(distribPackageMgmt)" in
			rpm) findPackage="rpm -qf"; searchPackage="yum whatprovides";;
			deb) findPackage="dpkg -S"; searchPackage="apt-file search";;
		esac
		if $findPackage $(which $executable | sed "s|/||");then
			:
		else
			if which $executable >/dev/null 2>&1
			then
				echo "=> Using : $searchPackage $(which $executable) ..." >&2
				$searchPackage $(which $executable)
			else
				echo "=> Using : $searchPackage bin/$executable ..." >&2
				$searchPackage bin/$executable
			fi
		fi
	done
}
function lsbin {
	for package
	do
		package=${package/:/}
		case "$(distribPackageMgmt)" in
			rpm) packageContents="rpm -ql";;
			deb) packageContents="dpkg -L";;
		esac
		$packageContents $package
	done | grep bin/ | sort -u
}
function fixAptKeys {
	time sudo apt-get update 2>&1 >/dev/null | awk '/Release:.*not available: NO_PUBKEY/{print "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$NF}' | sh -x
	sudo apt-key update
}
function fixAptKeysBis {
	time sudo apt-get update 2> /tmp/keymissing; for key in $(grep "NO_PUBKEY" /tmp/keymissing |sed "s/.*NO_PUBKEY //"); do echo -e "\nProcessing key: $key"; sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key ; done
	sudo apt-key update
}
function updateRepositoryKeys {
	time sudo apt-get update 2>&1 >/dev/null | awk '/Release:.*not available: NO_PUBKEY/{print "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$NF}' | sh -x
	sudo apt-key update
}
function reinstallOrignialPackages {
	local packagesList=$@
	test $# != 0 && sudo $(which apt) install -V $(printf "%s/$(lsb_release -sc) " $packagesList)
}
function timeprocess {
	local process=$1
	local pid=$(pidof "$1")
	test -z $pid || ps -o etime= $pid
}
function watchProcess {
	test $# = 1 && while true
	do
		\pgrep -lf "$1" && break
		sleep 1
	done | uniq
}
function website {
	$(which apt-cache) show $@ | egrep "Homepage:|Package:" | sort -u
#	open $($(which apt-cache) show $@ | egrep "Homepage:" | sort -u)
}
function cleanFirefoxLock {
	case $(lsb_release -si) in
		Debian) firefoxProgramName=iceweasel;;
		Ubuntu) firefoxProgramName=firefox;;
	esac

	pgrep -lf $firefoxProgramName || \rm -vf ~/.mozilla/firefox/*.default/lock ~/.mozilla/firefox/*.default/.parentlock
}
function myUnlink {
	for file
	do
		unlink $file
	done
}
function dfc {
	firstArg=$1
	if echo "$firstArg" | \egrep -q "^\-|^$"
	then
		args=$@
		$(which dfc) -TW $args
	else
		shift
		args=$@
		test "$args" && argsRE="|"$(tr -s / <<< $@ | tr " " "|" | sed "s,/$,,")
		firstArg="$(tr -s / <<< "$firstArg")"
		test "$firstArg" != / && firstArg="$(sed "s,/$,," <<< "$firstArg")"
		$(which dfc) -TWfc always | \egrep "FILESYSTEM|$firstArg$argsRE"
	fi
}
function aptGet {
	args=$@
	firstArg=$1
	case $firstArg in
	install|purge) sudo $(which apt) $args -V;;
	download)
		$(which apt-get) $args --print-uris
		$(which apt-get) $args;;
	*) $(which apt-get) $args;;
	esac
}
function apt_get {
	args=$@
	firstArg=$1
	case $firstArg in
	install|purge) sudo $(which apt) $args -V;;
	download) $(which apt-get) $args --print-uris && $(which apt-get) $args;;
	*) $(which apt-get) $args;;
	esac
}
function apt {
	args=$@
	firstArg=$1
	case $firstArg in
	install|purge) sudo $(which apt) $args -V;;
	*) $(which apt) $args;;
	esac
}
function aptitude {
	args=$@
	firstArg=$1
	case $firstArg in
	install|reinstall|purge) sudo $(which aptitude) $args -V;;
	*) $(which aptitude) $args;;
	esac
}
function httpserver {
	mkdir -p ~/log
#	fqdn=$(host $(hostname) | awk '/address/{print$1}')
	fqdn=localhost
	test $1 && port=$1 || port=1234
	test $port -lt 1024 && {
		echo "=> ERROR: Only root can bind to a tcp port lower than 1024." >&2
		return 1
	}

	$(which ps) -fu $USER | grep -v grep | grep -q SimpleHTTPServer && echo "=> SimpleHTTPServer is already running on http://$fqdn:$(\ps -fu $USER | grep -v awk | awk '/SimpleHTTPServer/{print$NF}')/" || {
		logfilePrefix=SimpleHTTPServer_$(date +%Y%m%d)
		nohup python -m SimpleHTTPServer $port >~/log/${logfilePrefix}.log 2>&1 &
		test $? = 0 && {
			echo "=> SimpleHTTPServer started on http://$fqdn:$port/"
			echo "=> logFile = ~/log/${logfilePrefix}.log"
		}
	}
}
function setTimestamps {
	for file
	do
		timestamp=$(echo "$file" | sed -r 's/[a-zA-Z._-]*//g;s/([0-9]{12})([0-9]{2})/\1.\2/')
		nbChars=${#timestamp}
		[ $nbChars = 12 ] && timestamp=${timestamp}.00
		touch -t $timestamp "$file"
	done
}
function web2pdf {
	local url="$1"
	local pdfFile="$2"
	wkhtmltopdf "$url" "$pdfFile"
}
function xpiInfo {
	for xpiFile
	do
		echo "=> xpiFile = $xpiFile"
		printf "em:id = "
		unzip -q -p $xpiFile install.rdf | egrep -m1 "em:id" | awk -F "<|>" '{print$3}'
		printf "em:name = "
		unzip -q -p $xpiFile install.rdf | egrep -m1 "em:name" | awk -F "<|>" '{print$3}'
		printf "em:version = "
		unzip -q -p $xpiFile install.rdf | egrep -m1 "em:version" | awk -F "<|>" '{print$3}'
		echo
	done
}
function apkInfo {
	for package
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The file $package does not exist." >&2; continue
		}

		aapt dump badging "$package" | awk -F"'" '/^package:/{print$(NF-1)}/application:|^package:/{print$2}/[Ss]dkVersion:/'
	done
}
function rename_APK {
	type aapt || return
	for package
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The package $package does not exist." >&2; continue
		}

		packagePath=$(dirname $package)
		packageID=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$2}')
		packageVersion=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$6}' | cut -d' ' -f1)
		packageNewFileName="$packagePath/$packageID-$packageVersion.apk"
		[ "$package" = $packageNewFileName ] || mv -v "$package" $packageNewFileName
	done
}
function rename_All_APKs {
	type aapt || return
	for package in $(\ls *.apk)
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The package $package does not exist." >&2; continue
		}

		if echo $package | egrep -q "^[^\.]+\.apk"
		then
			packagePath=$(dirname $package)
			packageID=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$2}')
			packageVersion=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$6}' | cut -d' ' -f1)
			packageNewFileName="$packagePath/$packageID-$packageVersion.apk"
			[ "$package" = $packageNewFileName ] || mv -v "$package" $packageNewFileName
		fi
	done
}
function apt_cache {
	args=$@
	command=$1
	if echo $command | grep -q search
	then
		shift
		args=$@
		$(which apt-cache) search $args | sort
	else
		$(which apt-cache) $@
	fi
}
function resizePics {
	for src
	do
		ext=$(echo "$src" | awk -F. '{print$NF}')
		dst="${src/.$ext/-SMALLER}.$ext"
		convert -verbose -resize '1024x768>' "$src" "$dst"
		touch -r "$src" "$dst"
	done
}
function resizePics_2048 {
	for src
	do
		ext=$(echo "$src" | awk -F. '{print$NF}')
		dst="${src/.$ext/-SMALLER}.$ext"
		convert -verbose -resize '2048x1536>' "$src" "$dst"
		touch -r "$src" "$dst"
	done
}
function find {
	dir=$1
	if echo $dir | \grep -q "\-"
	then
		dir=.
	else
		shift
	fi
#	firstPredicate=$1
#	shift
	args="$@"
	if echo $@ | \grep -q "\-ls"
	then
		args=${args/-ls/}
		$(which find) $dir $firstPredicate $args -printf "%10i %10k %M %n %-10u %-10g %10s %AY-%Am-%Ad %.12AX %p\n"
	else
#		$(which find) $dir $firstPredicate "$arg"
		$(which find) $dir $firstPredicate "$@"
	fi
}
function getBJC {
	#bjcUrl=http://www.bibledejesuschrist.org/downloads/bjc_internet.pdf
	bjcUrl=http://www.bibledejesuschrist.org/downloads/bjc.pdf
	extension=$(echo $bjcUrl | awk -F. '{print$NF}')
	bjcBaseName=$(basename $bjcUrl .$extension)
	echo "=> Downloading last BJC version ..."
	wget $bjcUrl
	\mv -v $bjcBaseName.$extension "${bjcBaseName}_$(date -d "$(stat -c %y $bjcBaseName.$extension)" +%Y%m%d_%HH%MM%S).$extension"
}
function webgrep {
	url=$1
	shift
	test $# -ge 1 && curl -s $url | egrep $@
}
function split4GiB {
	test $# = 1 && time split -d -b 4095m $1 $1.
}
function build_in_HOME {
	test -s configure || time ./bootstrap.sh || time ./bootstrap || time ./autogen.sh
	test -s Makefile || time ./configure --prefix=$HOME/gnu --sysconfdir=$HOME/gnu $@
	test -s Makefile && time make && make install
	test -s GNUmakefile && time make && make install
}
function build_in_usr {
	test -s configure || time ./bootstrap.sh || time ./bootstrap || time ./autogen.sh
	test -s Makefile || time ./configure --prefix=/usr --sysconfdir=/etc $@
	test -s Makefile && time make && sudo make install
	test -s GNUmakefile && time make && sudo make install
}
function build_in_usr_DEBIAN {
	test -s configure || time ./bootstrap.sh || time ./bootstrap || time ./autogen.sh
	test -s Makefile || time ./configure --prefix=/usr --sysconfdir=/etc $@
	test -s Makefile && time make && sudo make install
	test -s GNUmakefile && time make && sudo checkinstall
}
function build_in_usr_local {
	test -s configure || time ./bootstrap.sh || time ./bootstrap || time ./autogen.sh
	test -s Makefile || time ./configure --prefix=/usr/local $@
	test -s Makefile && time make && sudo make install
	test -s GNUmakefile && time make && sudo make install
}
function build_in_usr_local_DEBIAN {
	test -s configure || time ./bootstrap.sh || time ./bootstrap || time ./autogen.sh
	test -s Makefile || time ./configure --prefix=/usr/local $@
	test -s Makefile && time make && sudo checkinstall
	test -s GNUmakefile && time make && sudo checkinstall
}
function updateYoutubeLUAForVLC {
	if groups 2>/dev/null | egrep -wq "sudo|admin"
	then
		test $(uname -s) = Linux &&  \sudo \wget --content-disposition -NP /usr/lib/vlc/lua/playlist/ https://raw.githubusercontent.com/videolan/vlc/master/share/lua/playlist/youtube.lua
		test $(uname -s) = Darwin && \sudo \wget --content-disposition -NP /Applications/VLC.app/Contents/MacOS/share/lua/playlist/ https://raw.githubusercontent.com/videolan/vlc/master/share/lua/playlist/youtube.lua
	else
		\wget --content-disposition -NP ~/.local/share/vlc/lua/playlist/ https://raw.githubusercontent.com/videolan/vlc/master/share/lua/playlist/youtube.lua
	fi
}
function updateYoutubePlaylistLUAForVLC {
	if groups 2>/dev/null | egrep -wq "sudo|admin"
	then
		test $(uname -s) = Linux &&  \sudo \wget --content-disposition -NP /usr/lib/vlc/lua/playlist/ https://dl.opendesktop.org/api/files/download/id/1473753829/149909-playlist_youtube.lua
		test $(uname -s) = Darwin && \sudo \wget --content-disposition -NP /Applications/VLC.app/Contents/MacOS/share/lua/playlist/ https://dl.opendesktop.org/api/files/download/id/1473753829/149909-playlist_youtube.lua
	else
		wget --content-disposition -NP ~/.local/share/vlc/lua/playlist/ https://dl.opendesktop.org/api/files/download/id/1473753829/149909-playlist_youtube.lua
	fi
}
function locate {
	groups | \egrep -wq "sudo|admin" && locateOptions="-e" || locateOptions="--database $HOME/.local/lib/mlocate/mlocate.db -e"
	echo "$@" | grep -q "\-[a-z]*r" && $(which locate) $locateOptions "$@" || $(which locate) $locateOptions -ir "${@}"
}
function locateBin {
	locate "${@}" | grep bin/
}
function txt2pdf {
	for file
	do
		txt2ps "$file"
		\ps2pdf "${file/.*/.ps}"
		\rm -f "${file/.*/.ps}"
		echo "=> ${file/.*/.pdf}"
	done
}
function txt2ps {
	for file
	do
		\enscript -B "$file" -o "${file/.*/.ps}"
	done
}
function printrv {
	lp -o page-set=odd -o outputorder=reverse $1
	echo "=> Press enter once you have flipped the pages in the printer ..."
	read
	lp -o page-set=even $1
}

function renameExtension { test $# = 2 && shopt -s globstar && for f in **/*.$1; do /bin/mv -vi "$f" "${f/.$1/.$2}"; done; }
function aacDir2mp3 { shopt -s globstar && for f in **/*.aac; do /bin/mv -vi "$f" "${f/.aac/.m4a}"; done; time pacpl -v --eopts "-v" -r -k -t mp3 .; }

function downgradeTo {
	distribCodename=$1
	case $distribCodename in
		"-h"|"")
			echo "=> ERROR: Usage: $FUNCNAME [ <distribCodename> ] | downgrade current" >&2
			return -1
		;;
		"current")
			distribCodename=$(lsb_release -sc)
		;;
		*) #Ajouter une commande pour tester si le nom donne existe
		;;
	esac
	echo "=> distribCodename = $distribCodename"
	sudo sed -i".$(date +%Y%m%d)" "s/$(lsb_release -sc)/$distribCodename/" /etc/apt/sources.list
	if test -s /etc/apt/preferences.d/99-downgrade
	then
		time sudo $(which apt) update
		sudo $(which apt) dist-upgrade -V
	else
		echo "=> ERROR: The file </etc/apt/preferences.d/99-downgrade> does not exist, generating it ..." >&2 && {
			cat <<-EOF
			Package: *
			Pin: release a=$distribCodename
			Pin-Priority: 1001

			Package: *
			Pin: release a=$distribCodename-updates
			Pin-Priority: 1001

			Package: *
			Pin: release a=$distribCodename-security
			Pin-Priority: 1001

			Package: *
			Pin: release a=$distribCodename-backports
			Pin-Priority: 1001

			Package: *
			Pin: release a=$distribCodename-proposed
			Pin-Priority: -1
EOF
		} | sudo tee /etc/apt/preferences.d/99-downgrade
		echo "=> Please re-run the <downgrade> function." >&2
		return 1
	fi
}
function totalSize {
	local column=$1
	awk -v "column=$column" '{total+=$column}END{if(total>2^30)print total/2^30" GiB" > "/dev/stderr"; else if(total>2^20) print total/2^20" MiB" > "/dev/stderr"; else if(total>2^10) print total/2^10" KiB" > "/dev/stderr"; else print total" Bytes" > "/dev/stderr";}'
}
function rsyncIncludeOnly {
	local destination="$(eval echo \$$#)"
	local rsyncCommandSuffix="--include='*/' --exclude='*'"
	local rsyncCommand="$(which rsync) -r -uth -P -z"

	for arg
	do
		[ "$arg" = $destination ] && break
		if grep -q '*' <<< "$arg"
		then
			rsyncCommand="$rsyncCommand --include=\"$arg\""
		else
			rsyncCommand="$rsyncCommand $arg"
		fi
	done
set +x
	echo "=> INFO: Running: $rsyncCommand $rsyncCommandSuffix $destination" >&2
	time $rsyncCommand $rsyncCommandSuffix $destination;
	echo "=> Syncing disks ..."
	time sync
}
function reload_SHELL_Functions_And_Aliases {
#	for script in ~/.${0}rc $initDir/.*functions $initDir/.*aliases $initDir/.*aliases.$(uname -s)
	for script in $initDir/.*functions $initDir/.*aliases $initDir/.*aliases.$(uname -s)
	do
		source $script
	done
}
function mplayer {
	which mplayer >/dev/null 2>&1 && {
		if tty | grep -q "/dev/pts/[0-9]"; then
			$(which mplayer) -idx -geometry 0%:100% "$@" 2> /dev/null | egrep "stream |dump|Track |VIDEO:|AUDIO:|VO:|AO:|A:"
		else
			if [ -c /dev/fb0 ]; then
				if [ ! -w /dev/fb0 ]; then
				groups | grep -wq video || \sudo adduser $USER video
				\sudo chmod g+w /dev/fb0
				fi
				$(which mplayer) -vo fbdev2 -idx "$@" 2> /dev/null | egrep "stream |dump|Track |VIDEO:|AUDIO:|VO:|AO:|A:"
			else
				echo "=> Function $FUNCNAME - ERROR: Framebuffer is not supported in this configuration." 1>&2
				return 1
			fi
		fi
	}
}
function mpv {
	which mpv >/dev/null && {
	local youtube_dl=$(which youtube-dl)
	for urlOrFile; do
		echo $urlOrFile | egrep -q "(http|ftp)s?://" && $youtube_dl -qs $urlOrFile 2>&1 | grep --color=auto --color -A1 ^ERROR: && continue
		if tty | egrep -q "/dev/pts/[0-9]|/dev/ttys[0-9]+"; then
			$(which mpv) -geometry 0%:100% "$@"
		else
			if [ -c /dev/fb0 ]; then
				if [ ! -w /dev/fb0 ]; then
				groups | grep -wq video || \sudo adduser $USER video
				\sudo chmod g+w /dev/fb0
				fi
				$(which mpv) -vo drm "$@"
			else
				echo "=> Function $FUNCNAME - ERROR: Framebuffer is not supported in this configuration." 1>&2
				return 1
			fi
		fi
	done
	}
}
function ddPV {
	test $# -lt 2 && {
		echo "=> Usage: $FUNCNAME if=FILE of=FILE OPTIONS ..." >&2
		return -1
	}
	input=$1
	inputFile=$(echo $input | awk -F= '{print$2}')
	shift
	#echo "=> sudo pv --wait $inputFile | sudo dd $@ ..."
	#time sudo pv --wait $inputFile | sudo dd $@
	echo "=> sudo bash -c \"pv $inputFile | dd $@\" ..."
	time sudo bash -c "pv $inputFile | dd $@"
}
