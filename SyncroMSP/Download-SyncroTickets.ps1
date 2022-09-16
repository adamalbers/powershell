# Download all the SyncroMSP tickets and save them to a JSON file which can be manipulated in other programs.

# Copy syncro-example.json to syncro.json and modify as necessary.
# The .gitignore for this repo will ignore any file name 'syncro.json' so you won't accidentally upload your config to GitHub.
$pathToJSON = "./syncro.json"

##### DO NOT CHANGE ANYTHING BELOW THIS LINE #####

$syncroSettings = Get-Content $pathToJSON | ConvertFrom-Json -Depth 100

$subdomain = "$($syncroSettings.subdomain)" 
$apiToken = "$($syncroSettings.apiToken)"
$outputPath = "$($syncroSettings.outputPath)"

$headers = @{
    "Authorization" = "$apiToken"
    "Accept"        = "application/json"
}

$urlBase = "https://$subdomain.syncromsp.com/api/v1/"

function getTickets {
    param($pageNumber, $updatedSince )

    if ($updatedSince) {
        $result = Invoke-RestMethod -Uri "$urlBase/tickets?page=$($pageNumber)&since_updated_at=$($updatedSince)" -Headers $headers
    }
    else {
        $result = Invoke-RestMethod -Uri "$urlBase/tickets?page=$($pageNumber)" -Headers $headers
    }
    
    return $result
}


# Check to see if there is already content at $outputPath
$existingTickets = Get-Content $outputPath -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 100 | Sort-Object updated_at -Descending

if ($existingTickets) {
    $lastUpdated = (Get-Date $existingTickets[0].updated_at -Format yyyy-MM-dd).ToString()
    Write-Output "Found existing data at $outputPath with most recent update on $lastUpdated."
    Write-Output "Will request all tickets that have been updated since $lastUpdated."
}

$newTickets = @()
$currentPage = 1

do {
    Write-Host -ForegroundColor Green "Downloading page $currentPage of $totalPages."
    $results = getTickets $currentPage $lastUpdated
    $totalPages = $results.meta.total_pages
    $newTickets += $results.tickets
    $currentPage++
    Write-Output "Sleeping 500ms because of Syncro API rate limits."
    Start-Sleep -Milliseconds 500
} while ($currentPage -le $totalPages)

# Add any existing tickets before we write to file
$newTickets += $existingTickets

# Sort the tickets by number and use Sort-Object to remove duplicates
# Since Syncro only accepts a date (no time) in the since_updated_at parameter, you will get duplicates if you run this more than once a day.
$newTickets = $newTickets | Sort-Object Number -Descending -Unique

Write-Host -ForegroundColor Green "`n##### DOWNLOAD COMPLETE #####"
Write-Host "Saving to $outputPath"
$newTickets | ConvertTo-Json -Depth 100 | Out-File $outputPath
Write-Host -ForegroundColor Green "Done."

Exit 0