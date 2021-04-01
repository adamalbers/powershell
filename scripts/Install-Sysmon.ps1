$sysmonURL = 'http://live.sysinternals.com/tools/Sysmon64.exe'
$sysmonConfigURL = 'https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml'

$sysmonPath = "$Env:Temp\sysmon64.exe"
$sysmonConfigPath = "$Env:Temp\sysmonconfig.xml"

# Exit if 32-bit OS.
if ((Get-CimInstance Win32_OperatingSystem).OSArchitecture -ne "64-bit") {
    Write-Output "32-bit OS detected. Exiting."
    Exit 1
}

# Set $ProgressPrefence to silent to speed up downloads and then download files.
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $sysmonURL -OutFile $sysmonPath
Invoke-WebRequest -Uri $sysmonConfigURL -OutFile $sysmonConfigPath

# If 32-bit sysmon is installed, remove it.
if (Get-Service sysmon -ErrorAction 'SilentlyContinue') {
    Write-Output "Removing 32-bit sysmon."
    Start-Process -FilePath $sysmonPath -ArgumentList "-u -force"
}

# Install or update sysmon64
if (Get-Service sysmon64*) {
    Write-Output "Updating sysmon config with $sysmonConfigPath."
    Start-Process -FilePath $sysmonPath -ArgumentList "-c $sysmonConfigPath" -Wait
} 
else {
    Write-Output "Installing 64-bit sysmon with $sysmonConfigPath"
    Start-Process -FilePath $sysmonPath -ArgumentList "-accepteula -i $sysmonConfigPath" -Wait
}

# Set sysmon log max size of 256MB and set it to archive instead of overwrite old events.
Write-Output "Configuring 256MB max size and archiving for Microsoft-Windows-Sysmon/Operational log."
Start-Process wevtutil.exe -ArgumentList 'sl Microsoft-Windows-Sysmon/Operational /rt:true /ab:true /ms:268435456' -Wait

# Cleanup
Remove-Item $sysmonPath -Force -Confirm:$false
Remove-Item $sysmonConfigPath -Force -Confirm:$false

Exit 0