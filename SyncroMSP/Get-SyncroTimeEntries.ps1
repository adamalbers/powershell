# Download all the SyncroMSP ticket_timers and save them to a JSON file which can be manipulated in other programs.

# Copy syncro-example.json to syncro.json and modify as necessary.
# Better yet, encrypt it to syncro.json.secret with Keybase.
# The .gitignore for this repo will ignore any file name 'syncro.json' so you won't accidentally upload your config to GitHub.

Param( 
    $configName = 'syncro.json.secret'
)

# ----- DO NOT MODIFY BELOW THIS LINE ----- #
Write-Host "Searching for $configName in configs directory."
$config = Import-Config $configName

Write-Host '------------------------------'

if (-not $config) {
    Write-Host -ForegroundColor Red 'Could not import config. Exiting.'
    Exit 1
}

$subdomain = "$($config.subdomain)" 
$apiToken = "$($config.apiToken)"
$outputPath = "$($config.timeEntriesPath)"

$headers = @{
    'Authorization' = "$apiToken"
    'Accept'        = 'application/json'
}

$urlBase = "https://$subdomain.syncromsp.com/api/v1/"

function getTimeEntries {
    param($pageNumber, $updatedSince )

    if ($updatedSince) {
        $result = Invoke-RestMethod -Uri "$urlBase/ticket_timers?page=$($pageNumber)&created_at_gt=$($updatedSince)" -Headers $headers
    }
    else {
        $result = Invoke-RestMethod -Uri "$urlBase/ticket_timers?page=$($pageNumber)" -Headers $headers
    }
    
    return $result
}


# Check to see if there is already content at $outputPath
if ((Test-Path $outputPath -ErrorAction 'SilentlyContinue')) {
    # Have to use Get-ChildItem first because [System.IO.File] won't like a relative path.
    $file = (Get-ChildItem -Path $outputPath)
    #$reader = [System.IO.File]::OpenText($file)
    #$existingTimeEntries = $reader.ReadToEnd() | ConvertFrom-Json -Depth 100 | Sort-Object updated_at -Descending
    #$reader.Close()
    $existingTimeEntries = Get-FileContent $file
}
else {
    Write-Host "Did not find any existing $outputPath."
}


if ($existingTimeEntries) {
    $lastUpdated = (Get-Date $existingTimeEntries[0].updated_at -Format yyyy-MM-dd).ToString()
    Write-Host -ForegroundColor Green "Found existing data at $outputPath with most recent update on $lastUpdated."
    Write-Host -ForegroundColor Green "Will request all ticket_timers that have been updated since $lastUpdated."
    Write-Host '------------------------------'
}

$newTimeEntries = @()
$currentPage = 1

do {
    Write-Host -ForegroundColor Green "Downloading page $currentPage of $totalPages."
    $results = getTimeEntries $currentPage $lastUpdated
    $totalPages = $results.meta.total_pages
    $newTimeEntries += $results.ticket_timers
    $currentPage++
    
    # Sleep 500ms because of Syncro API rate limits.
    Start-Sleep -Milliseconds 500
} while ($currentPage -le $totalPages)

# Add any existing ticket_timers before we write to file
$newTimeEntries += $existingTimeEntries

# Sort the ticket_timers by number and use Sort-Object to remove duplicates
# Since Syncro only accepts a date (no time) in the since_updated_at parameter, you will get duplicates if you run this more than once a day.
$newTimeEntries = $newTimeEntries | Sort-Object ticket_id -Descending 

Write-Host -ForegroundColor Green "`n#----- DOWNLOAD COMPLETE -----#"
Write-Host '------------------------------'
Write-Host "Saving to $outputPath"
$newTimeEntries | ConvertTo-Json -Depth 100 | Out-File $outputPath
Write-Host -ForegroundColor Green "Done.`n"

Exit 0