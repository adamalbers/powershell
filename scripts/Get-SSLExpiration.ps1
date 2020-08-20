$url = "https://www.example.com"
$daysToAlert = 21 # Will trigger if certificate expires in this many or fewer days.

### You should not need to change anything below this line. ###

$webRequest = Invoke-WebRequest $url
$servicePoint = [System.Net.ServicePointManager]::FindServicePoint($url)

$certificate = $servicePoint.Certificate

$today = Get-Date
$expirationDate = $certificate.GetExpirationDateString()

$timeSpan = New-TimeSpan -Start $today -End $expirationDate

$daysToExpiration = $timeSpan.Days

Write-Output "$daysToExpiration days until certificate expires."

# Exit with error if expiration date not available.
if (!($daysToExpiration)) {
    Write-Output "Unable to find certificate expiration date."
    Exit 1
}

# Alert if expiration date is less than 21 days away.
if ($daysToExpiration -lte $daysToAlert) {
    Write-Output "Certificate for $url expires in less than 20 days."
}

Exit 0