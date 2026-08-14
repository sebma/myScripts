Get-PnpDevice -Class HIDClass -Status OK | Where-Object FriendlyName -match "FIDO|Thetis|Security|Authenticator" | Format-Table -AutoSize
