@reg query hklm\system\currentcontrolset\control\citrix | findstr -i "HKEY_LOCAL_MACHINE\system\currentcontrolset\control\citrix\XMLService ProductBuild ProductName ProductVersionNum NewProductVersion ICAProductMinorVersion NewServicePack"
@echo.
@psinfo -s | findstr -i citrix
