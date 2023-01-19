Param( 
    $ConfigName = 'syncro.json.secret',
    $OutputFolder,
    $ApiToken,
    $Subdomain,
    $ApiEndpoints
)

# ----- DO NOT MODIFY BELOW THIS LINE ----- #

function Get-SyncroConfig {
    Param (
        $configKey
    )

    $configValue = "$($config.$configKey)"

    return $configValue
}


function Get-Response {
    Param (
        [Parameter(Mandatory)] $apiEndpoint,
        [Parameter(Mandatory)] $page,
        $totalPages
    )

    $headers = @{
        'Authorization' = "$ApiToken"
        'Accept'        = 'application/json'
    }

    $urlBase = "https://$Subdomain.syncromsp.com/api/v1"
    $url = "${urlBase}/${apiEndpoint}"

    if ($page -eq 1) {
        Write-Host -ForegroundColor Green "Requesting page $page of `'${apiEndpoint}`' from ${url} ..."
    }

    if ($page -gt 1) {
        Write-Host -ForegroundColor Green "Downloading page $page of $totalPages."
    }
    
    try {
        $response = Invoke-RestMethod -Uri "${url}?page=${page}" -Headers $headers
    }
    catch {
        $message = $($_.Exception.Message)
        Write-Host -ForegroundColor Red "`nFailed when attempting to query the " -NoNewline
        Write-Host -ForegroundColor Cyan "$apiEndpoint" -NoNewline
        Write-Host -ForegroundColor Red ' API endpoint.'
        Write-Host -ForegroundColor Red "`nError when attemping to query ${url}?page=${page}"
        Write-Host -ForegroundColor Red $message
        Write-Host -ForegroundColor Yellow "`nPlease check for typos in your `$ApiEndpoints:"
        Write-Host $ApiEndpoints -Separator "`n"
        Write-Host -ForegroundColor Magenta "`nSee https://api-docs.syncromsp.com/ to verify available API endpoints.`n"
        Exit 1
    }
    

    # Fix conflicting key names if detected
    if (-not $($response.meta)) {
        # Syncro returns the notes field as 'Notes' or 'notes' sometimes and the different case will screw up the import.
        # Do some regex to make sure all the key names are lowercase.
        $response = $response | ConvertFrom-Json -Depth 100 -AsHashtable | ConvertTo-Json -Depth 100
        $response = [regex]::Replace($response, '(?<=")(.+)(?=":)', { $args[0].Groups[1].Value.ToLower() }) | ConvertFrom-Json -Depth 100
    }
    

    return $response
}

function Export-SyncroDataToJSON {
    Param (
        [Parameter(Mandatory)] [string]$apiEndpoint
    )

    $now = (Get-Date -Format yyyy-MM-dd_hhmmss)

    $results = @()
    $page = 1
    $totalPages = 1

    # Make sure the $OutputFolder exists before we try to download all this stuff.
    if (-not (Test-Path $OutputFolder)) {
        Write-Host -ForegroundColor Red "`nConfigured output folder not found:"
        Write-Host -ForegroundColor Cyan "$OutputFolder`n"
    }

    Write-Host -ForegroundColor Cyan "Requesting data from Syncro using the `'$apiEndpoint`' API endpoint...`n"

    do {
        # Query the Syncro API
        $response = $response = Get-Response $apiEndpoint $page $totalPages
    
        $totalPages = $response.meta.total_pages
        $results += $response.$dataName
    
        $page ++
    
        # Sleep 400ms because of Syncro API rate limits.
        Start-Sleep -Milliseconds 400
    } while ($page -le $totalPages)

    # Find the name of the data field in the response e.g. assets,invoices,customers
    $dataName = ($response | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -ne 'meta' }).Name
    $dataNameUpper = $($dataName.ToUpper())
    
    # Set JSON export path
    $subfolder = "${OutputFolder}/${dataName}"
    if (-not (Test-Path $subfolder)) {
        New-Item -Type Directory -Path $subfolder -Force
    }
    $outputPath = "$subfolder/${now}_${dataName}.json"

    # Export data
    Write-Host -ForegroundColor Green "`nExporting $dataNameUpper to `'$outputPath`'`n"
    $results | ConvertTo-Json -Depth 100 | Out-File $outputPath

    $finished = "Finished exporting $dataNameUpper."
    
    return $finished
}

Write-Host "Searching for $ConfigName in $configsPath."
$config = Import-Config $ConfigName

Write-Host '------------------------------'

if (-not $config) {
    Write-Host -ForegroundColor Red "`nCould not import config. Will prompt for values.`n"
}

# Check the script parameters and if any are not defined, grab them from the config file
$ParameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters

foreach ($key in $ParameterList.keys) {
    $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
    $varName = $($var.Name)
    $varValue = $($var.Value)
    
    # Look for a value in the config file
    if (-not $varValue -and $config) {
        Write-Host -ForegroundColor Cyan "`$$varName not defined. Looking for value in config file: $ConfigName"
        $varValue = Get-SyncroConfig $varName
        Set-Variable -Name $varName -Value $varValue
    }

    if (-not $varValue) {
        $varValue = Read-Host "Enter value for ${varName}"
        Set-Variable -Name $varName -Value $varValue
    }
}

# Split comma separated list into array
$ApiEndpoints = $ApiEndpoints -split ',' 

# Loop through all $ApiEndpoints and export the data
foreach ($apiEndpoint in $ApiEndpoints) {
    $exportResult = Export-SyncroDataToJSON $apiEndpoint
    Write-Host -ForegroundColor Cyan "$exportResult`n"
}

Exit 0