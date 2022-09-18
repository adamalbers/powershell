# This is intended to be run on a client machine via our RMM.
# It will install our Comet Backups agent and log activity to our RMM.
# If you don't use SyncroRMM, you'll see some errors but install should still work as long as
# you define the variables below.

# Import RMM module
Import-Module $env:SyncroModule

# ----- SET VARIABLES ----- #
<# We pull all these variables from our RMM. If you don't set these at runtime via your RMM, you need to uncomment this section and define all these variables.

$server = "backups.example.com:443" # You really only need the port if it's NOT 443
$adminUsername = "admin"
$adminPassword = "superDuperSecretAndLongPassword"
$cometUsername = "backups@example.com"
$cometPassword = "fakePassword@34"

#>

# ----- DO NOT MODIFY BELOW THIS LINE ----- #
$serviceName = "backup.delegate"
$command = "$Env:Temp\install.exe /CONFIGURE=${cometUsername}:${cometPassword}"
$zipPath = "$Env:Temp\comet.zip"


# Exit script if variables not set.
if (-not $server) {
    Write-Warning 'Missing $server. Cannot continue.'
    Exit 1
}

if (-not $adminUsername) {
    Write-Warning 'Missing $adminUsername. Cannot continue.'
    Exit 1
}

if (-not $adminPassword) {
    Write-Warning 'Missing $adminPassword. Cannot continue.'
    Exit 1
}

if (-not $cometUsername) {
    Write-Warning 'Missing $cometUsername. Cannot continue.'
    Exit 1
}

if (-not $cometPassword) {
    Write-Warning 'Missing $cometPassword. Cannot continue.'
    Exit 1
}

# Determine 64-bit or 32-bit and set the download URL as such.
if ((Get-CimInstance -ClassName Cim_OperatingSystem).OSArchitecture -eq "64-bit") {
    $downloadURL = "https://${server}/api/v1/admin/branding/generate-client/windows-x86_64-zip"
}
else {
    $downloadURL = "https://${server}/api/v1/admin/branding/generate-client/windows-x86_32-zip"
}

# Force TLS 1.2 encryption for the web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download the Comet installer zip file
Invoke-Webrequest -Uri "$downloadURL" -Method POST -Body @{Username = "${adminUsername}"; AuthType = "Password"; Password = "${adminPassword}" } -OutFile $zipPath
    
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    if ((Get-Service $serviceName).Status -eq 'Running') {
        # do nothing
        Write-Output "Backup service already installed and running. Exiting."
        Exit 0
    }
    else {
        Write-Output "$serviceName found, but it is not running for some reason."
        Write-Output "Attempting to start $servicename."
        Start-Service $serviceName
        Exit 0
    }
}
else {
    Write-Output "$serviceName not found. Installing."
    
    Expand-Archive -Path "$zipPath" -DestinationPath "$Env:Temp"
    
    Set-Location -Path "$Env:Temp"
    Invoke-Expression $command
    
    Start-Sleep -Seconds 20
    Remove-Item "$Env:Temp\install.dat"
    Remove-Item "$Env:Temp\install.exe"
    Remove-Item "$zipPath"
    

}

Log-Activity -Message "Installed Comet backups agent." -EventName "Comet Install"

Exit 0