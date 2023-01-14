Import-Module ActiveDirectory

$today = (Get-Date -Format 'yyyy-MM-dd')
$domainName = (Get-ADDomain).DNSRoot -replace '\.', '-'
$reportPath = "$Env:Temp\${today}-${domainName}-hotfix-report.csv"

if (-not $startDate) {
    $startDate = (Get-Date).Year
}

$startDate = (Get-Date $startDate)

$computers = Get-ADComputer -Filter 'Enabled -eq "true"' -Properties * | Where-Object { $_.LastLogonDate -ge $startDate }

foreach ($computer in $computers) {
    Write-Output "Getting updates on $($computer.Name)..."
    Invoke-Command -ComputerName $($computer.Name) -ScriptBlock { 
        Get-HotFix | Where-Object { $_.InstalledOn -ge $startDate } | `
            Sort-Object InstalledOn } -ErrorAction SilentlyContinue | `
        Select-Object PSComputername, HotfixID, InstalledOn | `
        Export-Csv -Path "$reportPath" -NoTypeInformation -Append
}


Exit 0