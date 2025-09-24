Set-NetFirewallRule -Name FPS-ICMP4-ERQ-In -Enabled true
Get-NetFirewallRule -Name FPS-ICMP4-ERQ-In | % Enabled
