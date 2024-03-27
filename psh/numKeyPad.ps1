mount HKU Registry HKEY_USERS
sp "HKU:\.DEFAULT\Control Panel\Keyboard" -n InitialKeyboardIndicators -v 2
gpv "HKU:\.DEFAULT\Control Panel\Keyboard" -n InitialKeyboardIndicators
Remove-PSDrive HKU
gpv "HKCU:\Control Panel\Keyboard" -n InitialKeyboardIndicators
