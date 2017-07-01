
if not defined atTime set atTime=%1
echo @wmic printer list brief ^> D:\listPrinters.log > D:\listPrinters.cmd
::schtasks -create -s %USERDOMAIN%\service1000
