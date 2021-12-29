

if (!(Get-PackageProvider -Name NuGet)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

if (!(Get-Module -Name VMware.PowerCLI)) {
    Install-Module VMware.PowerCLI -Force
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Connect-VIServer -Server 192.168.42.201 -Protocol HTTPS -User "username" -Password "password"