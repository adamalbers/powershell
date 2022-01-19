$email = 'alerts@example.com'

# These variables come from our RMM but you should uncomment and set them here if running manually.
# Currently this script only does verification using Cloudflare DNS with an API Token.
# Choose LE_STAGE for testing or LE_PROD for a real cert.

# $leServerType = 'LE_STAGE'
# $certNames = @('www.example.com','example.com', 'www2.example.com')
# $apiToken = 'superSecretLongAPIToken'
# $deployToRDS = 'no'
# $deployToExchange = 'no'
# $deployToIIS = 'no'

##### DO NOT MODIFY BELOW THIS LINE #####

if ((-not $certNames) -or (-not $apiToken)) {
    Write-Output '$certNames and $apiToken are required. Exiting.'
    Exit 1
}

# We send a comma separated string from our RMM so we parse it here.
# This won't have any effect if you set $certNames manually above.
$certNameList = @()
$certNameList = $certNames.Split(',')

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

# Get certificate from LE with Cloudflare DNS challenge
$pluginArgs = @{
	CFToken = $( $apiToken | ConvertTo-SecureString -AsPlainText -Force)
}
if ($(Get-PAOrder -List -ErrorAction 'SilentlyContinue').Name -contains $certNames) {
    Set-PAOrder $certNames
    $cert = Submit-Renewal
} else {
    $cert = New-PACertificate $certNameList -AcceptTOS -Contact $email -Plugin Cloudflare -PluginArgs $pluginArgs -Install
}

Write-Output $cert | Format-List

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
if ($deployToIIS) {
    Write-Output "Enabling $($cert.Name) on IIS Default Web Site."
    $cert | Set-IISCertificate -SiteName 'Default Web Site' -RemoveOldCert
}

Exit 0