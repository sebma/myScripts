if( $(alias cd *>$null;$?) ) {
	del alias:cd
}

set-alias historyLocal Get-History
if ( $(alias history *>$null;$?) ) { del alias:history }

#if ( $(alias ls *>$null;$?) ) { del alias:ls }
#set-alias -Scope Global more less.exe
#set-alias -Scope Global openssl "${ENV:ProgramFiles(x86)}\LogMeIn\x64\openssl.exe"
set-alias -Scope Global winmerge "${ENV:ProgramFiles}\WinMerge\WinMergeU.exe"

if ( $(alias curl *>$null;$?) ) { del alias:curl }
if ( $(alias ip *>$null;$?) ) { del alias:ip }
if ( $(alias rm *>$null;$?) ) { del alias:rm }
set-alias -Scope Global id whoisUSER
if( isInstalled("ls.exe") ) {
	$global:ls = "ls.exe"
	set-alias -Scope Global l $ls
}
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
set-alias -Scope Global more less  		
#if( ! (alias wget 2>$null | sls wget) ) { set-alias -Scope Global wget Invoke-WebRequest }
#if(alias man 2>$null | sls man) {
#	del alias:man
#	function man { help @args | less }
#}




