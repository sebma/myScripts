Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True
Get-NetFirewallProfile | Format-Table Name, Enabled
