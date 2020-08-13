Import-Module $env:SyncroModule

$installerPath = "$Env:Temp\sentinelinstaller.exe"

# Exit if SentinelOne token not defined for customer.
if (!($sentinelOneToken)) {
    Write-Output "Installation cannot continue."
    Write-Output "Please ensure the Sentinel One Token custom field is populated for this customer."
    Exit 1
}
else {
    $sentinelOneToken = $sentinelOneToken.Trim()
}

# Exit if SentinelOne is already installed.
if (Get-Service SentinelAgent -ErrorAction SilentlyContinue) {
    Write-Output "SentinelOne service already exists. Please uninstall before attempting to reinstall."
    Exit 1
}

# Determine if this is a workstation or a server.
if ($operatingSystem -eq $null) {
    $operatingSystem = (Get-CimInstance -ClassName Cim_OperatingSystem).Caption
}

if ($operatingSystem -match "Server") {
    		$deviceType = "Server"
		} else {
			$deviceType = "Workstation"
		}

# Install only if the box is checked to enable server or workstation install.
if (($serverInstall -eq "yes" -and $deviceType -eq "Server") -or ($workstationInstall -eq "yes" -and $deviceType -eq "Workstation")) {
    Start-Process -FilePath $installerPath -ArgumentList "/SITE_TOKEN=$sentinelOneToken /SILENT"
    Exit 0
}
else {
    Write-Output "Did not attempt to install SentinelOne. Please verify either the 'SentinelOne Workstation Install' or 'SentinelOne Server Install' customer custom field is checked."
    Exit 1
}



Exit 1