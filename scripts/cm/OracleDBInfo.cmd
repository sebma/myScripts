@echo off
set logFile=%~dp0\%computername%_%~n0.log
set sqlFile=%~dp0\%computername%_%~n0.sql
set expUser=exp

echo. >nul && (
	echo select banner "Version" from v$version ;
	echo select sum^(bytes^)/power^(2,30^) "Database_Size_Go" from dba_segments where owner in ^('ANTI','F24','FAS3','INCA','ISIB'^);
	echo select sum^(bytes^)/power^(2,30^) "Physical_Database_Size_Go" from dba_data_files;
	echo set pages 20
	echo select sum^(bytes^)/power^(2,20^) "Tablespace_Size_Mo", Tablespace_Name "Tablespace_Name" from dba_segments group by tablespace_name;
	echo exit
) > %sqlFile%

sqlplus -s %expUser%/%expUser% @%sqlFile% > %logFile% && del %sqlFile%
type %logFile%

if not %computername%==DMIL2K01 del %0 else pause
exit/b

