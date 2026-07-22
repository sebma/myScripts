@echo off
net localgroup ora_dba %username% /add >nul 2>&1
echo /* Version du moteur Oracle */
echo select banner "Version" from v$version ; | sqlplus -s "/ as sysdba"
if not %computername%==DMIL2K01 net localgroup ora_dba %username% /del >nul 2>&1
