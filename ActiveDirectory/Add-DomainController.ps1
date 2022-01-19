$domainName = Read-Host "Enter name of domain to join e.g. ad.example.com: "
$credentials = (Get-Credential -Message "Domain Admin" -Username "DOMAIN\Username")
$featureCheck = Get-WindowsFeature | Where-Object {$_.Installed -eq 'True' -and $_.Name -eq 'AD-Domain-Services'}

$nics = Get-NetIPInterface -AddressFamily 'IPv4' | Where-Object {$_.Dhcp -eq 'Disabled' -and $_.InterfaceAlias -notmatch "Loop" }

if (-not $nics) {
	Write-Output "Need at least one NIC with a static IP. Exiting."
	Exit 1
}

if (-not $featureCheck) {
	Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
}

Install-ADDSDomainController -DomainName "$domainName" -InstallDns:$true -Credential $credentials

Exit 0