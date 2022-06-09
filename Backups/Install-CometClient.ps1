#Import-Module $env:SyncroModule

$adminUsername = "admin"
$adminPassword = "admin"
$server = "backups.example.com:443" # You really only need the port if it's not 443
$serviceName = "backup.delegate"
$command = "$Env:Temp\install.exe /CONFIGURE=${cometUsername}:${cometPassword}"
$zipPath = "$Env:Temp\comet.zip"

# This is the account you want to create for a Comet backups user.
# I have commented out these lines because we pull them from our RMM.
#$cometUsername = "backups@example.com"
#$cometPassword = "fakePassword@34"

# Exit script if either cometUsername or cometPassword are not populated in RMM (or defined above).
if (($cometUsername -eq $null) -or ($cometPassword -eq $null)) {
    Write-Output "Please populate the Comet Backups User and Comet Backups Password fields in the customer custom fields before running this script."
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
    
    # Function allows us to unzip the file.
    function Unzip {
        param([string]$zipFile, [string]$outPath)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $outPath)
    }
    Unzip "$zipPath" "$Env:Temp"
    
    Set-Location -Path "$Env:Temp"
    Invoke-Expression $command
    
    Start-Sleep -Seconds 20
    Remove-Item "$Env:Temp\install.dat"
    Remove-Item "$Env:Temp\install.exe"
    Remove-Item "$zipPath"
    

}

#Log-Activity -Message "Installed Comet backups agent." -EventName "Comet Install"

Exit 0