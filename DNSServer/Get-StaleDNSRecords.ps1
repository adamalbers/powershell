# Will find records older than this many days
$days = '365'

# Find name of domain to which this script host belongs
$domainName = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

# Get stale DNS records
$staleRecords = Get-DnsServerResourceRecord -ZoneName $domainName | `
    Where-Object { $_.RecordType -eq 'A' -and $_.Timestamp -lt $($(Get-Date).AddDays(-$days)) -and $_.Timestamp -ne $null} | `
    Sort-Object Timestamp

