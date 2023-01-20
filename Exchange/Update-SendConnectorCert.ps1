# Update send connector certs to match the SMTP cert
Param (
    $CertDomain = $(Read-Host 'Enter cert subject domain e.g. mail.example.com')
)

# Add Exchange management snapin
try {
    $ErrorActionPreference = 'Stop'
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
}
catch {
    Write-Warning $_
    Write-Host -ForegroundColor Yellow "`nPlease verify snap in spelling and version and try again.`n"
    Exit 1
}

# Find the newest cert matching $CertDomain
$cert = Get-ExchangeCertificate | Where-Object { $_.CertificateDomains -match $CertDomain -and $_.NotBefore -le $(Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1

# Create a $certName in the format required by Set-SendConnector
# See: https://learn.microsoft.com/en-us/powershell/module/exchange/set-sendconnector?view=exchange-ps
$certName = "<I>$($cert.Issuer)<S>$($cert.Subject)"

# Get expired certs with matching $CertDomain
$oldCerts = Get-ExchangeCertificate | Where-Object { $_.CertificateDomains -match $CertDomain -and $_.NotAfter -lt $(Get-Date) }

# Find the send connector(s) using the cert
$sendConnectorName = (Get-SendConnector | Where-Object { $_.TlsCertificateName.SubjectCommonName -match $CertDomain }).Identity.Name

# Have to clear the current TlsCertificateName in case the issuer and subject are identical on the old and new certs
Set-SendConnector -Identity $SendConnectorName -TlsCertificateName $null

# Remove the expired cert so they cannot be used
if ($oldCerts) {
    Remove-ExchangeCertificate -Thumbprint $($oldCerts.Thumbprint) -Confirm:$false
}

# Assign the new cert
Set-SendConnector -Identity $SendConnectorName -TlsCertificateName $certName

# Verify the new cert is assigned
(Get-SendConnector -Identity $SendConnectorName).TlsCertificateName

Exit 0