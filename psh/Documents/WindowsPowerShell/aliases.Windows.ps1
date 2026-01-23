if( $(alias curl *>$null;echo $?) ) { del alias:curl }
if( $(alias ip *>$null;echo $?) ) { del alias:ip }
if( $(alias rm *>$null;echo $?) ) { del alias:rm }
if( $(alias tee *>$null;echo $?) ) { del -Force alias:tee }
if( $(alias wget *>$null;echo $?) ) { del alias:wget }

#if(alias man 2>$null | sls man) { del alias:man }
#function man { help @args | less }

#if ( $(alias ls *>$null;$?) ) { del alias:ls }
if( isInstalled("ls.exe") ) {
	$global:ls = "ls.exe"
	set-alias -Scope Global l $ls
}

#set-alias -Scope Global openssl "${ENV:ProgramFiles(x86)}\LogMeIn\x64\openssl.exe"
set-alias -Scope Global winmerge "${ENV:ProgramFiles}\WinMerge\WinMergeU.exe"
set-alias historyLocal Get-History
set-alias -Scope Global id whoisUSER
set-alias -Scope Global lscom lsserial
set-alias -Scope Global np notepad
set-alias -Scope Global np++ notepad++
set-alias -Scope Global np1 notepad1
set-alias -Scope Global np2 notepad2
set-alias -Scope Global np3 notepad3
set-alias -Scope Global np4 notepad4
set-alias -Scope Global nppp notepad++
set-alias -Scope Global reboot restart-computer
set-alias ipa ipv4
set-alias ipl iplink
set-alias ipr iproute
set-alias mac@ iplink
set-alias mac iplink
set-alias -Scope Global more less

