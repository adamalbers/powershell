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
$outputPath = "$($config.customersPath)"
$customers = @()

$headers = @{
    'Authorization' = "$apiToken"
    'Accept'        = 'application/json'
}

$urlBase = "https://$subdomain.syncromsp.com/api/v1/"

$page = 1
$totalPages = 2

do {
    $response = Invoke-RestMethod -Uri "$urlBase/customers?page=$page" -Headers $headers
    $totalPages = $response.meta.total_pages
    $customers += $response.customers
    $page ++
    
    # Sleep 500ms because of Syncro API rate limits.
    Start-Sleep -Milliseconds 500
} while ($page -le $totalPages)

$customers = $customers | Sort-Object business_name

Write-Host -ForegroundColor Green "`n#----- DOWNLOAD COMPLETE -----#"
Write-Host '------------------------------'
Write-Host "Saving to $outputPath"
$customers | ConvertTo-Json -Depth 100 | Out-File $outputPath

Exit 0