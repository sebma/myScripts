@echo off

set SPFileName=%1
set destDir=%2

if not defined SPFileName (
	echo =^> Usage : %~nx0 "SPFileName" "destDir" >&2
	exit/b 1
)

if not defined destDir (
	echo =^> Usage : %~nx0 "SPFileName" "destDir" >&2
	exit/b 1
)

if not exist %SPFileName% (
	echo =^> Warning: The file "%SPFileName%" does not exit. >&2
	exit/b 2
)

if not exist %destDir% mkdir %destDir%

rmdir/q/s %tmp%\Tmp
mkdir %tmp%\Tmp
start/w %SPFileName% -u -x:%tmp%\Tmp

if "%~n1"=="xpsp1a_fr_x86" ( start/b %tmp%\Tmp\update\update -u -s:%destDir% ) else start/b %tmp%\Tmp\i386\update\update -u -s:%destDir%

REM mkisofs -volid "WinXPSP1a" -allow-multidot -no-iso-translate -relaxed-filenames -allow-leading-dots -N -l -d -D -joliet-long -duplicates-once -no-emul-boot -b boot.bin -hide-joliet boot.bin -hide-joliet boot.catalog -gui -o "%userprofile%\Bureau\WinLite.iso" "F:\WinXPProSP1a"
