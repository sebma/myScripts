@echo off
set user=%1
if not defined user set user=%username%
echo =^> User creation date :
for /f %%w in ('dsquery user -name %user%') do adfind -list -tdcgts -tdcsfmt "%%DD%%/%%MM%%/%%YYYY%%-%%HH%%:%%mm%%:%%ss%% %%TZ%%" -b %%w whenCreated
