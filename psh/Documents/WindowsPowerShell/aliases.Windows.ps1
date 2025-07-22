#if ( $(alias ls *>$null;$?) ) { del alias:ls }
if ( $(alias rm *>$null;$?) ) { del alias:rm }
if ( $(alias ip *>$null;$?) ) { del alias:ip }
if ( $(alias curl *>$null;$?) ) { del alias:curl }
set-alias ipa ipv4
set-alias ipl iplink
set-alias mac@ iplink
set-alias ipr iproute
set-alias -Scope Global l ls.exe
set-alias -Scope Global np notepad
set-alias -Scope Global np4 notepad4
set-alias -Scope Global np++ notepad++
set-alias -Scope Global nppp notepad++
set-alias -Scope Global reboot restart-computer
#set-alias -Scope Global more less.exe
#set-alias -Scope Global openssl "${ENV:ProgramFiles(x86)}\LogMeIn\x64\openssl.exe"
