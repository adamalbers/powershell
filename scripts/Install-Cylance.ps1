<#
.SYNOPSIS
    Install Cylance using provided MSI download link and installation token
.DESCRIPTION
    This script can be used to download and install Cylance.
.NOTES
    File Name  : Install-Cylance.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers
#>

$downloadURL = ""
$token = ""

$msiPath = "$Env:Temp\cylance.msi"

# Download the installer
if ((Get-Command Invoke-WebRequest)) {
    Invoke-WebRequest -Uri $downloadURL -OutFile $msiPath
}
else {
    (New-Object System.Net.WebClient).DownloadFile($downloadURL, $msiPath)
}

# Attempt to uninstall any existing Cylance
if ((Get-Service CylanceSvc)) {
    $cylanceGUID = Get-WmiObject -Class win32_Product | Where-Object {$_.Name -match "Cylance PROTECT"} | Select-Object -ExpandProperty IdentifyingNumber
    Start-Process -FilePath "$Env:systemroot\system32\msiexec.exe" -ArgumentList "/x $cylanceGUID /qn /norestart /L*v $Env:Temp\cylance-uninstall.log" -Wait
}

# Install Cylance
Start-Process -FilePath "$Env:systemroot\system32\msiexec.exe" -ArgumentList "/i $msiPath /qn /norestart PIDKEY=$token /L*v $Env:Temp\cylance-install.log" -Wait

Exit 0