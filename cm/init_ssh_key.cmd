@echo off
set shared_network_drive=P:
if not exist %shared_network_drive%\.ssh\ mkdir %shared_network_drive%\.ssh\
copy /y %username%.ppk %shared_network_drive%\.ssh\
attrib -a +s +h %shared_network_drive%\.ssh\%username%.ppk
xcacls %shared_network_drive%\.ssh\%username%.ppk /g %username%:r /y
