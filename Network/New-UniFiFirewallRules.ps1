Import-Module NetSecurity

# Remove any existing UniFi rules
Get-NetFirewallRule -DisplayName "UniFi*" | Remove-NetFirewallRule -Confirm:$false

# Define TCP and UDP ports and create rules
# https://help.ui.com/hc/en-us/articles/218506997-UniFi-Ports-Used
$tcpPorts = @("8080", "8443", "8880", "8843", "6789", "27117")
$udpPorts = @("3478", "5514", "5656-5699", "10001", "1900")

New-NetFirewallRule -DisplayName "UniFi Controller TCP" -Direction Inbound -LocalPort $tcpPorts -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "UniFi Controller UDP" -Direction Inbound -LocalPort $udpPorts -Protocol UDP -Action Allow

Exit 0