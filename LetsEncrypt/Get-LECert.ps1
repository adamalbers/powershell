$email = 'alerts@example.com'

# Currently this script only verification using Cloudflare DNS with an API Token or HTTP if $apiToken is null.

# These variables come from our RMM but you should uncomment and set them here if running manually.
# Choose LE_STAGE for testing or LE_PROD for a real cert.
# $leServerType = 'LE_STAGE'
# $certNames = @('www.example.com','example.com', 'www2.example.com')
# $apiToken = 'superSecretLongAPIToken'
# $deployToRDS = 'no'
# $deployToExchange = 'no'
# $deployToIIS = 'no'

##### DO NOT MODIFY BELOW THIS LINE #####

if (-not $certNames) {
    Write-Output '$certNames are required. Exiting.'
    Exit 1
}

# We send a comma or newline separated list from our RMM so we parse it here.
# This won't have any effect if you set $certNames manually above.
$certNameList = @()
if ($certNames -contains ',') {
    $certNameList = $certNames.Split(',')
} else {
    $certNameList = $certNames.Split([Environment]::NewLine)
}

# Set Powershell to use TLS 1.2 as required by Install-PackageProvider and Install-Module
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
if (-not (Get-PackageProvider -Name NuGet -ErrorAction 'SilentlyContinue')) {
	Install-PackageProvider -Name NuGet -Confirm:$false -Force
}

if (-not (Get-Module -Name Posh-ACME -ErrorAction 'SilentlyContinue')) {
	Install-Module -Name Posh-ACME -Confirm:$false -Force -Scope AllUsers
}

if (-not (Get-Module -Name Posh-ACME.Deploy -ErrorAction 'SilentlyContinue')) {
    Install-Module -Name Posh-ACME.Deploy -Confirm:$false -Force -Scope AllUsers
}

Import-Module Posh-ACME
Import-Module Posh-ACME.Deploy
Import-Module RemoteDesktopServices

# Choose LE production or staging server
Set-PAServer $leServerType

# Add API token to pluginArgs if token was provided or use HTTP verification if not.
if ($apiToken) {
    $plugin = 'Cloudflare'
    $pluginArgs = @{
	    CFToken = $( $apiToken | ConvertTo-SecureString -AsPlainText -Force)
    }
} else {
    $plugin = 'WebRoot'
    $webRootPath = (Get-Website -Name 'Default Web Site').PhysicalPath
    $webRootPath = $webRootPath.Replace('%SystemDrive%',"$Env:SystemDrive")
    $pluginARgs = @{
        WRPath = "$webRootPath"
    }
}

# Check if there is an existing cert.
if ($(Get-PAOrder -List).Name -contains $certNameList[0]) {
    $expiryDate = (Get-PAOrder -Name $($certNameList[0])).CertExpires
    $timespan = New-TimeSpan -Start (Get-Date) -End $expiryDate
    if ($($timespan.Days) -gt 30) {
        Write-Output "$($certNameList[0]) cert expires: $expiryDate"
        Write-Output "Found certificate but it is more than 30 days out from renewal. Exiting."
        Exit 0
    }
    
    Set-PAOrder $certNameList[0]
    Write-Output "Found $($certNameList[0]). Running renewal."
    $cert = Submit-Renewal
} else {
    Write-Output "Requesting new certificate."
    $cert = New-PACertificate $certNameList -AcceptTOS -Contact $email -Plugin $plugin -PluginArgs $pluginArgs -Install
}

Write-Output $cert | Format-List

# Exit before the deployment steps if LE_PROD is not selected.
if ($leServerType -ne 'LE_PROD') {
    Write-Output '$leServerType is NOT LE_PROD. Exiting without any deployment.'
    Exit 0
}

# Exit before the deployment steps if cert was not eligible to be renewed.
if ($cert -match 'is not recommended for renewal yet') {
    Write-Output "Cert is not close enough to renewal date to be renewed. Exiting without any deployment."
    Exit 0
}

# Deploy cert to Remote Desktop Services if selected
if ($deployToRDS -eq 'yes') {
    Write-Output "Enabling $($cert.Name) on RDS Gateway."
    $cert | Set-RDGWCertificate

    Write-Output "Enabling $($cert.Name) on RDS Listener."
    $cert | Set-RDSHCertificate
}

# Deploy cert to Exchange if selected
if ($deployToExchange -eq 'yes') {
    Write-Output "Enabling $($cert.Name) on Exchange."
    $cert | Set-ExchangeCertificate
}

# Deploy cert to IIS if selected
if ($deployToIIS -eq 'yes') {
    Write-Output "Enabling $($cert.Name) on IIS Default Web Site."
    $cert | Set-IISCertificate -SiteName 'Default Web Site' -RemoveOldCert
}

Exit 0