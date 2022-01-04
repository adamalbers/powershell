$subdomain = 'example'
$apiToken = 'aaaaBBBBccccDDDDeeee'

$headers = @{
    "Authorization" = "$apiToken"
    "Accept" = "*/*"
}

$urlBase = "https://$subdomain.syncromsp.com/api/v1/"


function getCustomers {
    $query = Read-Host "`nEnter business name: "

    $url = "$urlBase/customers?business_name=$query"

    Write-Host $url

    $response = Invoke-RestMethod -Method GET -Headers $headers -Uri $url

    if ($response.meta.total_entries -eq '0') {
        Write-Host "`n`nNo customers found matching `'$query`'. Exiting.`n"
        Exit 1
    }

    $customers = $response.customers

    if ($response.meta.total_pages -gt 1) {
        $i = 2
        while ($i -le $($response.meta.total_pages)) {
            $response = Invoke-RestMethod -Method GET -Headers $headers -Uri "$url&page=$i"
            $customers += $response.customers
            $i++
        }
    }

    return $customers
}

function getTickets {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Int32]
        $customerID
    )

    $url = "$urlBase/tickets?customer_id=$customerID"

    Write-Host $url`n
    
    $response = Invoke-RestMethod -Method GET -Headers $headers -Uri "$url"

    if ($response.meta.total_entries -eq '0') {
        Write-Host "`n`nNo tickets found for customer ID `'$customerID`'. Exiting.`n"
        Exit 1
    }

    $tickets = $response.tickets

    if ($response.meta.total_pages -gt 1) {
        $i = 2
        while ($i -le $($response.meta.total_pages)) {
            $response = Invoke-RestMethod -Method GET -Headers $headers -Uri "$url&page=$i"
            $tickets += $response.tickets
            $i++
        }
    }

    return $tickets
}

$customers = getCustomers

if ($customers.Length -gt 1) {
    Write-Host -ForegroundColor Green "`n***Multiple customers found.***"
    $customers | Sort-Object business_name | Select-Object business_name, id | Format-Table
    $customerID = Read-Host "Enter the customer ID you want from the list above: "
} else {
    $customerID = $customers[0].id
}

$tickets = getTickets($customerID) | Where-Object {$_.customer_id -eq $customerID} | Sort-Object number

$selection = @('number', 'id', 'created_at', 'subject')

$customerName = $($tickets[0].customer_business_then_name)
$ticketCount = $(($tickets | Measure-Object).Count)

Write-Host -ForegroundColor Yellow "$customerName Tickets"
$tickets | Select-Object -Last 10 | Format-Table $selection

Write-Host "Showing the 10 most recent tickets for $customerName."
Write-Host "Found $ticketCount total tickets for $customerName.`n"

Exit 0