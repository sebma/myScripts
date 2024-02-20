mount HKU Registry HKEY_USERS
sp "HKU:\.DEFAULT\Control Panel\Keyboard" -n InitialKeyboardIndicators -v 2
gpv "HKU:\.DEFAULT\Control Panel\Keyboard" -n InitialKeyboardIndicators
gpv "HKCU:\Control Panel\Keyboard" -n InitialKeyboardIndicators
