@echo off
sc config remoteaccess start= demand
sc qc remoteaccess | findstr START_TYPE
net start remoteaccess
netsh interface ip sh ipa
net stop remoteaccess
sc config remoteaccess start= disabled
sc qc remoteaccess | findstr START_TYPE
