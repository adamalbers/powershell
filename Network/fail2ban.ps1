$ErrorActionPreference = "SilentlyContinue"

# Search Security event logs for IPs with more than 4 failed login events in the past 10 min.
$attackerIPs = Get-EventLog -LogName "Security" -InstanceId 4625 -After (Get-Date).AddMinutes(-10) | Select-Object @{Label="SourceIP";Expression={$_.ReplacementStrings[-2]}} | Group-Object -Property SourceIP | Where-Object {$_.Count -gt 4} | Sort-Object -Property Count -Descending

if ($attackerIPs -eq $null) {
    Write-Output "No IPs to ban. Exiting."
    Set-NetFirewallRule -DisplayName "fail2ban" -RemoteAddress "1.2.3.4"
    
    Exit 0    
}

Write-Output $attackerIPs

# Add $attackerIPs to the fail2ban firewall rule. This replaces all existing IPs in the rule and thus unbans IPs after the 10 minute window.
if (Get-NetFirewallRule -DisplayName "fail2ban") {
    Set-NetFirewallRule -DisplayName "fail2ban" -RemoteAddress $($attackerIPs.Name)
    
	Exit 0
}
else {
	New-NetFirewallRule -DisplayName "fail2ban" -RemoteAddress $($attackerIPs.Name) -Direction Inbound -Action Block -Protocol Any
}


Exit 0