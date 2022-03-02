# YOu need an API key from https://freegeoip.app/
$apiKey = 'superSecretLongAPIKey'
# The IP list file should have one IPv4 or one IPv6 address per line.
$pathToIPFile = '~/Downloads/ipList.txt'
#$pathToMMDBInspect = '/opt/homebrew/bin/mmdbinspect'
#$pathToMaxMindCityDB = '/opt/homebrew/var/GeoIP/GeoLite2-City.mmdb'
$outputCSVPath = '~/Downloads/ipLocations.csv'

###### DO NOT CHANGE ANYTHING BELOW THIS LINE ######

$ips = Get-Content $pathToIPFile | Select-Object -Unique

$locations = [System.Collections.ArrayList]::new()

$baseURL = 'https://api.freegeoip.app/json/'

foreach ($ip in $ips) {
    $url = "$($baseURL)$($ip)`?apikey=$($apiKey)"
    $response = Invoke-RestMethod -Uri $url
    $locations.Add($response) | Out-Null
}

$locations | Export-Csv $outputCSVPath -NoTypeInformation