Import-Module $env:SyncroModule

# Variables passed from Syncro and not defined in script.
# $urlList

$daysToAlert = 700 # Will trigger if certificate expires in this many or fewer days.

### You should not need to change anything below this line. ###

# If $urlList isn't passed from the Syncro, exit script with error.
# Make sure your customer custom field text area is populated with a list of URLs, one per line.
if (!($urlList)) {
    Write-Output "No $urlList defined. Exiting."
    Exit 1
}
else {
    $urlList = $urlList.Split()
}

$expirationList = @()

foreach ($url in $urlList) {
    Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null # Make the web request so .NET service point can find it.
    $servicePoint = [System.Net.ServicePointManager]::FindServicePoint($url)

    $certificate = $servicePoint.Certificate

    $today = Get-Date
    $expirationDate = $certificate.GetExpirationDateString()

    $timeSpan = New-TimeSpan -Start $today -End $expirationDate

    $daysToExpiration = $timeSpan.Days

    # Exit with error if expiration date not available.
    if (!($daysToExpiration)) {
        Write-Output "Unable to find certificate expiration date for $url."
        Exit 1
    }

    # If cert expires in $daysToAlert or fewer days, add it to arrray of expiring certs.
    if ($daysToExpiration -le $daysToAlert) {
        $certificateProperties = @{
            URL            = $url
            Subject        = $certificate.Subject
            ExpirationDate = $expirationDate
        }
        
        $certificateObject = New-Object psobject -Property $certificateProperties

        $expirationList += $certificateObject
    }

}

# If any certs are in $expirationList, create a ticket.
if ($expirationList) {
    #$ticket = Create-Syncro-Ticket -Subject "SSL Expirations" -IssueType "Other" -Status "New"
    #Create-Syncro-Ticket-Comment -TicketIdOrNumber $ticket.ticket.id -Subject "Issue" -Body "$expirationList" -Hidden "false" -DoNotEmail "true"
    Write-Output $expirationList
    Exit 0
}
else {
    Write-Output "No certificates expiring in $daysToAlert or fewer days."
}

Exit 0