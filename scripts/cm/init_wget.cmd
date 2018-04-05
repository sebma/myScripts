@echo off
set shared_network_drive=P:
set wgetrc=%shared_network_drive%\wget_sg.ini
setx wgetrc %shared_network_drive%\wget_sg.ini
copy /y wget_sg.ini %shared_network_drive%\
attrib -a +s +h %shared_network_drive%\wget_sg.ini
xcacls %shared_network_drive%\wget_sg.ini /g %username%:f /y
