# The $pfSenseIPAddresses is set by our RMM
Import-Module $env:SyncroModule

$command = "pfSense-upgrade -d -c"
$plinkPath = "$Env:Temp\plink.exe"
$privateKeyPath = "$Env:Temp\example.ppk"

# If pfSense address wasn't provided, use the default gateway IP.
if (!($pfSenseIPAddresses)) {
    $pfSenseIPAddresses = (Get-NetIPConfiguration).Ipv4DefaultGateway.NextHop
} else {
    $pfSenseIPAddresses = $pfSenseIPAddresses.Split([Environment]::NewLine)
}

Write-Output "Checking for Available Upgrades on:`n$pfSenseIPAddresses`n`n"

function checkForUpgrade {
    param (
        [string[]]$pfSenseIPAddress
    )
    
    $output = Write-Output y | & $plinkPath -i $privateKeyPath root@$pfSenseIPAddress $command

    return $output
} 

$upToDate = @()
$upgradeable = @()

foreach ($ipAddress in $pfSenseIPAddresses) {
    $results = checkForUpgrade $ipAddress

    if ($results -match "Your system is up to date") {
        $upToDate += $ipAddress
    } else {
        if ($results -match "version of pfSense is available") {
            $upgradeable += $ipAddress
        }
    }

}

Remove-Item $plinkPath -Force -Confirm:$false
Remove-Item $privateKeyPath -Force -Confirm:$false


Write-Output "`n`nAlready Up to Date:`n$upToDate`n"
Write-Output "Upgradeable:`n$upgradeable`n`n"

if ($upgradeable.Length -ge 1) {
    Rmm-Alert -Category 'pfsense_upgrade' -Body "pfSense upgrades available on $upgradeable"
}

Exit 0