Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
try {
    Enable-NetFirewallRule -DisplayGroup 'Network Discovery'
    Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
    Enable-NetFirewallRule -DisplayGroup 'Windows Management Instrumentation (WMI)'
    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
} catch {
    Write-Warning $_
}
    
try {
    Set-NetFirewallRule -DisplayGroup 'Network Discovery' -Enabled True -Profile Domain,Private
    Set-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -Enabled True -Profile Domain,Private
    Set-NetFirewallRule -DisplayGroup 'Windows Management Instrumentation (WMI)' -Enabled True -Profile Domain,Private
    Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Profile Domain,Private
} catch {
    Write-Warning $_
}

try {
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
} catch {
    Write-Warning $_
}

Exit 0