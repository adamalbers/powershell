$sysmonInstallerPath = "$Env:Temp\sysmon64.exe"
$sysmonConfigPath = "$Env:Temp\sysmonconfig.xml"

<#
# We use our RMM to download these files, but you can uncomment this block to do it all in the script.
$sysmonURL = 'https://live.sysinternals.com/tools/Sysmon64.exe'
$sysmonConfigURL = 'https://raw.githubusercontent.com/AMP-Systems-LLC/sysmon-config/ampsys-custom/sysmonconfig-export.xml'

# Set $ProgressPrefence to silent to speed up downloads and then download files.
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $sysmonURL -OutFile $sysmonInstallerPath -UseBasicParsing
Invoke-WebRequest -Uri $sysmonConfigURL -OutFile $sysmonConfigPath -UseBasicParsing
#>

# Get version of the installer so we can see if it's newer than the currently installed
$installerVersion = (Get-ItemProperty $sysmonInstallerPath -ErrorAction 'SilentlyContinue').VersionInfo.FileVersion

if (-not $installerVersion) {
    Write-Output 'Could not read version of the sysmon installer. Plese make sure file downloaded correctly. Exiting.'
    Exit 1
}

# Get version of currently installed
$currentSysmonPath = (Get-WmiObject -Class win32_service | Where-Object { $_.Name -match 'sysmon' }).PathName
$currentVersion = (Get-ItemProperty $currentSysmonPath -ErrorAction 'SilentlyContinue').VersionInfo.FileVersion

function uninstallSysmon {
    Write-Output "Removing outdated or broken sysmon"
    Stop-Process 'sysmon64' -Force -Confirm:$false -ErrorAction 'SilentlyContinue'
    Start-Process "sc.exe" -ArgumentList "delete sysmon64" -NoNewWindow
    Start-Process -FilePath $sysmonInstallerPath -ArgumentList "-u force" -NoNewWindow
}

function installSysmon {
    Write-Output "Installing 64-bit sysmon v$($installerVersion) with $sysmonConfigPath"
    Start-Process -FilePath $sysmonInstallerPath -ArgumentList "-accepteula -i $sysmonConfigPath" -Wait -NoNewWindow
}

function updateSysmonConfig {
    Write-Output "Updating sysmon config with $sysmonConfigPath."
    Start-Process -FilePath $sysmonInstallerPath -ArgumentList "-c $sysmonConfigPath" -Wait -NoNewWindow
}

function configureLogs {
    # Set sysmon log max size of 256MB and set it to archive instead of overwrite old events.
    Write-Output "Configuring 256MB max size and archiving for Microsoft-Windows-Sysmon/Operational log."
    Start-Process wevtutil.exe -ArgumentList 'sl Microsoft-Windows-Sysmon/Operational /rt:true /ab:true /ms:268435456' -Wait -NoNewWindow

    # Allow NETWORK SERVICE access to the Sysmon logs so the log can be part of event forwarding.
    Start-Process wevtutil.exe -ArgumentList 'sl Microsoft-Windows-Sysmon/Operational /ca:O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)' -Wait -NoNewWindow
}


# Exit if 32-bit OS.
if ((Get-CimInstance Win32_OperatingSystem -ErrorAction 'SilentlyContinue').OSArchitecture -ne "64-bit") {
    Write-Output "32-bit OS detected. Exiting."
    Exit 1
}

# If 32-bit sysmon is installed, remove it. (Service is named sysmon64 if 64-bit).
if (Get-Service sysmon -ErrorAction 'SilentlyContinue') {
    uninstallSysmon
}

# If sysmon64 isn't running, assume it's broken and remove it so it can be reinstalled.
if ((Get-Service sysmon64 -ErrorAction 'SilentlyContinue').Status -eq "Stopped") {
    uninstallSysmon
}

# Update sysmon64 if old version
if ($currentVersion -lt $installerVersion) { 
    uninstallSysmon
    installSysmon
    configureLogs
    Exit 0
}

# Install or update sysmon64
if (Get-Service sysmon64 -ErrorAction 'SilentlyContinue') {
    updateSysmonConfig
} 
else {
    installSysmon
}

# Cleanup
Remove-Item $sysmonInstallerPath -Force -Confirm:$false
Remove-Item $sysmonConfigPath -Force -Confirm:$false

Exit 0