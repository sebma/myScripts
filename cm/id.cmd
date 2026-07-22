@echo off
set user=%1
if not defined user set user=%username%

dsquery user -name %user% | dsget user -q -l -dn -samid -sid -upn -fn -mi -ln -display -empid -desc -office -tel -email -hometel -pager -mobile -fax -iptel -webpg -title -dept -company -mgr -hmdir -hmdrv -profile -loscr -mustchpwd -canchpwd -pwdneverexpires -disabled -acctexpires -reversiblepwd

for /f %%a in ('dsquery user -name %user%') do adfind -noctl -soao -alldc+ -nodn -tdcgts -tdcsfmt "%%DD%%/%%MM%%/%%YYYY%%-%%HH%%:%%mm%%:%%ss%% %%TZ%%" -b %%a
