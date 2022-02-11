# Script requires https://github.com/maxmind/geoipupdate and https://github.com/maxmind/mmdbinspect

# The IP list file should have one IPv4 address per line.
$pathToIPFile = '/path/to/ipList.txt'
$pathToMMDBInspect = 'mmdbinspect.exe'
$pathToMaxMindCityDB = '/path/to/GeoLite2-City.mmdb'
$outputCSVPath = '/path/to/example.csv'

###### DO NOT CHANGE ANYTHING BELOW THIS LINE ######

$ips = Get-Content $pathToIPFile

$locations = [System.Collections.ArrayList]@()

foreach ($ip in $ips) {
    $location = (& $pathToMMDBInspect --db $pathToMaxMindCityDB $ip) | ConvertFrom-Json -Depth 100

    $locationObject = [PSCustomObject]@{
        IP = $($location.Lookup)
        City = $($location.Records.Record.City.Names.En)
        State = $($location.Records.Record.Subdivisions.ISO_Code)
        PostalCode = $($location.Records.Record.Postal.Code)
        Country = $($location.Records.Record.Country.Names.En)
    }

    $locations.Add($locationObject) | Out-Null
}

$locations | Export-Csv $outputCSVPath -NoTypeInformation