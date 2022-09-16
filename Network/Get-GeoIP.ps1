# Requires https://github.com/maxmind/mmdbinspect for the IP lookups.
# The IP list file should have one IPv4 or one IPv6 address per line.

# Copy geoip-example.json to syncro.json and modify as necessary.
# The .gitignore for this repo will ignore any file name 'geoip.json' so you won't accidentally upload your config to GitHub.

$pathToJSON = "./geoip.json"

###### DO NOT CHANGE ANYTHING BELOW THIS LINE ######

$config = Get-Content $pathToJSON | ConvertFrom-Json -Depth 100
$pathToIPFile = $($config.pathToIPFile)
$pathToMMDBInspect = $($config.$pathToMMDBInspect)
$pathToMaxMindCityDB = $($config.$pathToMaxMindCityDB)
$pathToMaxMindASNDB = $($config.$pathToMaxMindASNDB)
$outputPath = $($config.outputPath)


$ips = Get-Content $pathToIPFile | Select-Object -Unique | Sort-Object

# Overwrite any existing $outputPath with an empty file
New-Item $outputPath -Force

foreach ($ip in $ips) {
    $locationData = & $pathToMMDBInspect -db $pathToMaxMindCityDB -db $pathToMaxMindASNDB $ip | ConvertFrom-Json -Depth 10
    $location = [PSCustomObject]@{
        IP       = $locationData[0].Lookup
        City     = $locationData[0].records.record.city.names.en
        Country  = $locationData[0].records.record.country.names.en
        ISO_Code = $locationData[0].records.record.country.iso_code
        ISP      = $locationData[1].records.record.autonomous_system_organization
        ASN      = $locationData[1].records.record.autonomous_system_number
    }
    
    $location | Export-Csv $outputPath -NoTypeInformation -Append
}

Exit 0