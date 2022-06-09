Import-Module $env:SyncroModule

###### Start Domain Controller Check ######
$osInfo = Get-CimInstance -ClassName win32_OperatingSystem
$productType = $osInfo.ProductType
$message = @'
Making sure this script is running on a domain controller.
ProductType indicates whether the computer is a workstation, server, or domain controller.

1 = Workstation
2 = Domain Controller
3 = Server

'@
Write-Host "`n$message`n"
Write-Host "Deteced Product Type: $productType`n"
if ($productType -ne '2') {
    Write-Host -ForegroundColor Red "This script is only meant to be run on domain controllers. Exiting.`n"
    Exit 0
}
else {
    Write-Host "Domain controller detected. Proceeding."
}
###### End Domain Controller Check ######

Import-Module ActiveDirectory

###### Start Service Health Checks ######
Write-Host -ForegroundColor Yellow "`n###### Start Service Health Checks ######"
$serviceNames = @('dfsr', 'dns', 'dnscache', 'eventsystem', 'ismserv', 'kdc', 'lanmanserver', 'lanmanworkstation', 'netlogon', 'ntds', 'rpcss', 'samss', 'w32time')
$services = Get-Service $serviceNames | Sort-Object Name

Write-Host "`nService Status:"
Write-Host "----------"
($services | Out-String).Trim()

$services | ForEach-Object {
    if ($_.Status -ne 'Running') {
        Write-Host -ForegroundColor Red "$($_.Name) is stopped. Attempting to start..."
        Start-Service $($_.Name)
        Start-Sleep -Seconds 10
        $newStatus = (Get-Service $($_.Name)).Status
        if ($newStatus -ne 'Running') {
            Write-Host -ForegroundColor Red "Could not start service. Please troubleshoot."
        }
        else {
            Write-Host -ForegroundColor Green "Successfully started $($_.Name)."
        }
    }
}
Write-Host -ForegroundColor Yellow "`n###### End Service Health Checks ######"
###### End Service Health Checks ######

###### Start Forest and Domain Health Checks ######
Write-Host -ForegroundColor Yellow "`n###### Start Forest and Domain Health Checks ######"
$forest = Get-ADForest

Write-Host "`nForest: $($forest.Name)"
Write-Host "----------"
($forest | Select-Object ForestMode, RootDomain, Domains, GlobalCatalogs, DomainNamingMaster, SchemaMaster | Format-List | Out-String).Trim()

$domain = Get-ADDomain
$domainControllers = Get-ADDomainController -Filter *
Write-Host "`nDomain: $($domain.DNSRoot)"
Write-Host "----------"
($domain | Select-Object Forest, DNSRoot, NetBIOSName, PDCEmulator, RIDMaster, InfrastructureMaster | Format-List | Out-String).Trim()

foreach ($domainController in $domainControllers) {
    $target = $($domainController.HostName)
    Write-Host "`nTesting Replication for $target"
    Write-Host "----------"
    $results = Get-ADReplicationFailure -Target $target
    if ($($results.FailureCount) -gt 0) {
        Write-Host -ForegroundColor Red "Errors found for $target."
        $message = ($results | Out-String).Trim()
        $message
        Rmm-Alert -Category 'ad_replication' -Body "$message"
    }
    else {
        Write-Host "No replication failures found for $target"
    }
}
Write-Host -ForegroundColor Yellow "`n###### End Forest and Domain Health Checks ######"
###### End Forest and Domain Health Checks ######

###### Start Windows Time Health Checks ######
Write-Host -ForegroundColor Yellow "`n###### Start Windows Time Health Checks ######"
Write-Host "`nCurrent System Date & Time: $(Get-Date)"
$logActivityEventName = 'w32time_check'
$logActivityMessage = 'System time configuration updated by script.'
$computerName = [System.Net.Dns]::GetHostByName($env:computerName).HostName.ToLower()
$pdcEmulator = $domain.PDCEmulator.ToLower()
$currentTimeSettings = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
$currentTimeType = $currentTimeSettings.Type
$currentNTPServers = $currentTimeSettings.NtpServer


if ($computerName -eq $pdcEmulator) {
    Write-Host "`nDetected that $computerName is the PDCEmulator. Checking w32time NTP server settings."
    $correctNTPServers = '0.pool.ntp.org,0x8 1.pool.ntp.org,0x8 2.pool.ntp.org,0x8 3.pool.ntp.org,0x8'
    Write-Host "Current NTP settings: $currentNTPServers"
    Write-Host "Desired NTP settings: $correctNTPServers"
    if ($currentNTPServers -ne $correctNTPServers) {
        Write-Host "`nNTP settings don't match. Updating NTP settings.`n"
        Write-Host "`nStopping w32time service."
        Stop-Service w32time
        Write-Host "`nRunning w32tm.exe /config /syncfromflags:manual /manualpeerlist:`"$correctNTPServers`""
        & w32tm.exe /config /syncfromflags:manual /manualpeerlist:"$correctNTPServers"
        Write-Host "`nRunning w32tm.exe /config /reliable:yes"
        & w32tm.exe /config /reliable:yes
        Write-Host "`nStarting w32time service."
        Start-Service w32time
        Write-Host "`nRunning w32tm.exe /resync"
        & w32tm.exe /resync
        $newNTPServers = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters).NtpServer
        Write-Host "`nNew NTP settings: $newNTPServers"
        Write-Host "New System Date & Time: $(Get-Date)"
        Log-Activity -Message "$logActivityMessage" -EventName "$logActivityEventName" | Out-Null
    }
    else {
        Write-Host "`nCurrent w32time NTP server settings are correct!"
    }
}
else {
    Write-Host -ForegroundColor Yellow "Detected that $computerName is NOT the PDCEmulator. Checking w32time configuration."
    $defaultType = 'NT5DS'
    if ($currentTimeType -ne $defaultType) {
        Write-Host "Non-default settings detected. Resetting w32time to default (use PDC Emulator as time source)."
        Write-Host "`nStopping w32time service."
        Stop-Service w32time
        Write-Host "`nRunning w32tm.exe /unregister"
        & w32tm.exe /unregister
        Write-Host "`nRunning w32tm.exe /register"
        & w32tm.exe /register
        Write-Host "`nStarting w32time service."
        Start-Service w32time
        Write-Host "`nRunning w32tm.exe /resync"
        & w32tm.exe /resync
        Write-Host "`nNew System Date & Time: $(Get-Date)"
        Log-Activity -Message "$logActivityMessage" -EventName "$logActivityEventName" | Out-Null
    }
    else {
        Write-Host "`nCurrent w32time configuration is correct."
    }
}
Write-Host -ForegroundColor Yellow "`n###### End Windows Time Health Checks ######"
###### End Windows Time Health Checks ######

Exit 0