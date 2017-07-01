@echo off
echo /* Version du moteur Oracle */
net localgroup ora_dba %username% /add >nul 2>&1
echo select sum(bytes)/power(2,30) "Database_Size_Go" from dba_segments; | sqlplus -s "/ as sysdba"
echo select sum(bytes)/power(2,30) "Physical_Database_Size_Go" from dba_data_files; | sqlplus -s "/ as sysdba"
if not %computername%==DMIL2K01 net localgroup ora_dba %username% /del >nul 2>&1
