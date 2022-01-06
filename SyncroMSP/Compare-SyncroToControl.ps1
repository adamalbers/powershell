<#
.Author Adam Albers

This script compares a list of computers from Connectwise Control to SyncroMSP.
It produces a CSV of computers that are present in CWC but NOT in SyncroMSP.
#>

$pathtoCSVReport = "$Env:HOME\Downloads\missingFromSyncro.csv"
##### BEGIN Connectwise Control Settings #####
# HTTPS IS REQUIRED
$controlServer = 'https://example.domain.com'

# This should be a read-only user in Control.
$controlUsername = 'readOnlyUser'
$controlPassword = 'superSecretLongPassword'
##### END Connectwise Control Settings #####

##### BEGIN SyncroMSP Settings #####
# This should be a read-only API token.
$syncroSubdomain = 'example'
$syncroAPIToken = 'aaaaBBBBccccDDDDeeee'
# This is our ID for the asset type Syncro Device. It may be different for other Syncro customers.
$syncroAssetTypeID = '84342'
##### END SyncroMSP Settings #####

#### DO NOT CHANGE ANYTHING BELOW HERE ####

##### GET CONTROL SESSIONS #####
# Make sure $controlServer has HTTPS
if ($controlServer -notmatch 'https://') {
    Write-Output "`nProvided URL: $controlServer"
    Write-Output "HTTPS is required. Exiting.`n"
    Exit 1
}

# Hide progress to make Invoke-WebRequest a bit faster
$ProgressPreference = 'SilentlyContinue'

function connectToControl {
    $controlCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($controlUsername):$($controlPassword)"))
    $headers = @{
        'authorization' = "Basic $controlCredentials"
        'content-type' = "application/json; charset=utf-8"
        'origin' = "$controlServer"
    }

    $controlResponse = Invoke-WebRequest -Uri $headers.origin -Headers $headers -UseBasicParsing
    $regex = [Regex]'(?<=antiForgeryToken":")(.*)(?=","isUserAdministrator)'
    $match = $regex.Match($controlResponse.content)
    if($match.Success){ $headers.'x-anti-forgery-token' = $match.Value.ToString() }
    else{ Write-Verbose 'Unable to find anti forgery token. Some commands may not work.' }

    $script:controlServerConnection = @{
        Server = $controlServer
        Headers = $headers
    }
}

function getComputers {
    $body = '[2,["All Machines"],"",null,null,null]'
    $controlResponse = Invoke-RestMethod -Headers $($controlServerConnection.Headers) -Method POST -Uri 'https://help.ampsysllc.com/Services/PageService.ashx/GetHostSessionInfo' -Body $body
    return $controlResponse.sessions | Sort-Object Name
}

Write-Host -ForegroundColor Green "Getting sessions from Connectwise Control..."
connectToControl
$controlSessions = getComputers

$controlCompanies = $controlSessions | ForEach-Object { $_.CustomPropertyValues[0] } | Select-Object -Unique | Sort-Object

Remove-Variable -Name controlServerConnection


###### GET SYNCRO ASSETS ######
$headers = @{
    "Authorization" = "$syncroAPIToken"
    "Accept" = "application/json"
}

$syncroURLBase = "https://$syncroSubdomain.syncromsp.com/api/v1"

function getAssets {
    $url = "$syncroURLBase/customer_assets`?asset_type_id=$syncroAssetTypeID"

    $syncroResponse = Invoke-RestMethod -Method GET -Headers $headers -Uri $url

    $totalPages = [Convert]::ToInt32($syncroResponse.meta.total_pages)
    $totalEntries = [Convert]::ToInt32($syncroResponse.meta.total_entries)

    if ($totalEntries -eq 0) {
        Write-Host "`n`nNo assets found. Exiting.`n"
        Exit 1
    }

    Write-Host -ForegroundColor Green "Getting assets from Syncro..."

    $syncroAssets = New-Object System.Collections.Generic.List[System.Object]
    
    $i = 1
    while ($i -le $($totalPages)) {
        $syncroResponse = Invoke-RestMethod -Method GET -Headers $headers -Uri "$url`&page=$i"
        foreach ($asset in $($syncroResponse.assets)) {
            $syncroAssets.Add($asset)
        }
        $i++
    }

    return $syncroAssets
}

$syncroAssets = getAssets

$syncroCustomers = $syncroAssets.customer.business_then_name | Select-Object -Unique | Sort-Object 

##### COMPARE CONTROL SESSIONS AND SYNCRO ASSETS #####
# Compare the customer lists and select matching companies
$mutualCompanies = @()
foreach ($company in $syncroCustomers) {
    if ($controlCompanies -contains $company) {
        $mutualCompanies += $company
    }
}

# Get the Control sessions for companies that exist in both Syncro and Control
$filteredControlSessions = @()
foreach ($session in $controlSessions) {
    if ($mutualCompanies -contains $($session.CustomPropertyValues[0])) {
        $filteredControlSessions += $session
    }
}

# Find assets that exist in Control but not in Syncro
$missingAssets = New-Object System.Collections.Generic.List[System.Object]

foreach ($asset in $filteredControlSessions) {
    if ($($syncroAssets.properties.'ScreenConnect GUID') -notcontains $($asset.SessionID)) {
        $missingAsset = [PSCustomObject]@{
            Company     = "$($asset.CustomPropertyValues[0])"
            Name        = "$($asset.Name)"
            Site        = "$($asset.CustomPropertyValues[1])"
            Department  = "$($asset.CustomPropertyValues[2])"
            Type        = "$($asset.CustomPropertyValues[3])"
            OS          = "$($asset.GuestOperatingSystemName)"
        }
        
        $missingAssets.Add($missingAsset)
    }
}

$missingAssets | Sort-Object Company | Export-Csv $pathtoCSVReport -NoTypeInformation

Exit 0