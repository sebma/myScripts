@echo off
;--------------------------------------------------------------------
;                UltraDefrag Boot Time Shell Script
;--------------------------------------------------------------------
; !!! NOTE: THIS FILE MUST BE SAVED IN UNICODE (UTF-16) ENCODING !!!
;--------------------------------------------------------------------

set UD_IN_FILTER=*windows*;*winnt*;*ntuser*;*pagefile.sys;*hiberfil.sys
set UD_EX_FILTER=*temp*;*tmp*;*dllcache*;*ServicePackFiles*

; to exclude archives too uncomment the follwing lines
; set UD_EX_FILTER=%UD_EX_FILTER%;*.7z;*.7z.*;*.arj;*.bz2;*.bzip2;*.cab;*.cpio
; set UD_EX_FILTER=%UD_EX_FILTER%;*.deb;*.dmg;*.gz;*.gzip;*.lha;*.lzh;*.lzma
; set UD_EX_FILTER=%UD_EX_FILTER%;*.rar;*.rpm;*.swm;*.tar;*.taz;*.tbz;*.tbz2
; set UD_EX_FILTER=%UD_EX_FILTER%;*.tgz;*.tpz;*.txz;*.xar;*.xz;*.z;*.zip

; uncomment the following line to create debugging output
; set UD_DBGPRINT_LEVEL=DETAILED

; uncomment the following line to save debugging information to a log file
; set UD_LOG_FILE_PATH=%UD_INSTALL_DIR%\Logs\defrag_native.log

udefrag %SystemDrive%

boot-off

exit
