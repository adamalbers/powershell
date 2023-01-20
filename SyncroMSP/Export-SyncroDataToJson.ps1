Param( 
    $ConfigName,
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
        $page,
        $totalPages
    )

    $headers = @{
        'Authorization' = "$ApiToken"
        'Accept'        = 'application/json'
    }

    $urlBase = "https://$Subdomain.syncromsp.com/api/v1"
    $url = "${urlBase}/${apiEndpoint}"

    if ($page -eq 1) {
        Write-Host -ForegroundColor Green "Requesting `'${apiEndpoint}`' data from ${url} ..."
    }

    if ($totalPages) {
        $url = "${url}?page=${page}"
        Write-Host -ForegroundColor Green "Downloading page $page of $totalPages."
    }
    
    try {
        $response = Invoke-RestMethod -Uri "${url}" -Headers $headers
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
        $ErrorActionPreference = 'SilentlyContinue'
        $cleanedResponse = $response | ConvertFrom-Json -Depth 100 -AsHashtable | ConvertTo-Json -Depth 100
        $cleanedResponse = [regex]::Replace($cleanedResponse, '(?<=")(.+)(?=":)', { $args[0].Groups[1].Value.ToLower() }) | ConvertFrom-Json -Depth 100
        $ErrorActionPreference = 'SilentlyContinue'
        
        # Use $cleanedResponse only if it worked
        if ($cleanedResponse) {
            $response = $cleanedResponse
        }
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

    # Make sure the $OutputFolder exists before we try to download all this stuff.
    if (-not (Test-Path $OutputFolder)) {
        Write-Host -ForegroundColor Red "`nConfigured output folder not found:"
        Write-Host -ForegroundColor Cyan "$OutputFolder`n"
        Write-Host -ForegroundColor Red "`nPlease check spelling and create $OutputFolder if needed.`n"
        Exit 1
    }

    Write-Host -ForegroundColor Cyan "Requesting data from Syncro using the `'$apiEndpoint`' API endpoint...`n"

    $response = $response = Get-Response $apiEndpoint $page
    $page++

    if ($($response.meta)) {
        $totalPages = $response.meta.total_pages
        # Find the name of the data field in the response e.g. assets,invoices,customers
        $dataName = ($response | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -ne 'meta' }).Name
        $results += $response.$dataName
    }
    
    if (-not $($response.meta)) {
        $dataName = $apiEndpoint
        $results += $response
    }

    # Create UPPERCASE $dataName for use in some output
    $dataNameUpper = $($dataName.ToUpper())

    # Download all pages if more than 1 page of results exists.
    do {
        # Query the Syncro API
        $response = $response = Get-Response $apiEndpoint $page $totalPages
        
        if ($($response.meta)) {
            $totalPages = $response.meta.total_pages
            $results += $response.$dataName
        }
        
        if (-not $($response.meta)) {
            $results += $response.$dataName
        }
        
        $page ++
    
        # Sleep 400ms because of Syncro API rate limits.
        Start-Sleep -Milliseconds 400
    } while ($totalPages -and $page -le $totalPages)
    
    # Set JSON export path
    $subfolder = "${OutputFolder}/${dataName}"
    if (-not (Test-Path $subfolder)) {
        New-Item -Type Directory -Path $subfolder -Force
    }
    $outputPath = "$subfolder/${now}_${dataName}.json"

    # Export data
    Write-Host -ForegroundColor Green "`nExporting $dataNameUpper to `'$outputPath`'`n"
    $resultsJson = $results | ConvertTo-Json -Depth 100 
    $resultsJson | Out-File $outputPath

    Write-Host "Finished exporting $dataNameUpper.`n"
    
    return $results
}

if (-not $ConfigName) {
    $ConfigName = Read-Host 'Enter name of config file e.g. syncro.json.secret or press Enter to manually input values'
}

if ($ConfigName) {
    Write-Host "Searching for $ConfigName in $configsPath."
    $config = Import-Config $ConfigName -ErrorAction 'SilentlyContinue'
}

Write-Host "------------------------------`n"

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
    if (-not $varValue -and $($config.$varName)) {
        Write-Host -ForegroundColor Cyan "`$$varName found in $ConfigName"
        $varValue = Get-SyncroConfig $varName
        Set-Variable -Name $varName -Value $varValue
    }

    if (-not $varValue) {
        Write-Host 'The variable ' -NoNewline
        Write-Host "`$${varName}" -NoNewline
        Write-Host ' is not defined.'
        $varValue = Read-Host "Enter value for ${varName}"
        Set-Variable -Name $varName -Value $varValue
    }
}

# Split comma separated list into array
$ApiEndpoints = $ApiEndpoints -split ',' 

# Loop through all $ApiEndpoints and export the data
foreach ($apiEndpoint in $ApiEndpoints) {
    Export-SyncroDataToJSON $apiEndpoint | Out-Null
}

Write-Host -ForegroundColor Green "`n`n##### FINISHED #####`n`n"

Exit 0