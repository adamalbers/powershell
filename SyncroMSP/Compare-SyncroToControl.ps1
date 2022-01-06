<#
.Author Adam Albers

This script compares a list of computers from Connectwise Control to SyncroMSP.
It produces a CSV of computers that are present in CWC but NOT in SyncroMSP.
#>

$pathtoCSVReport = "$Env:HOME\Downloads\missingFromSyncro-$(Get-Date -Format yyyy-MM-dd).csv"
##### BEGIN Connectwise Control Settings #####
# HTTPS IS REQUIRED
$controlServer = 'https://example.domain.com'

# This should be a read-only user in Control.
$controlUsername = 'exampleUser'
$controlPassword = 'SuperLongSuperSecretPassword'
##### END Connectwise Control Settings #####

##### BEGIN SyncroMSP Settings #####
# Use a read-only API token.
$syncroSubdomain = 'example'
$syncroAPIToken = 'aaaaaBBBBBcccccDDDDDeeeee'
<# 
This is our ID for the asset type Syncro Device. It may be different for other Syncro customers.
Asset type ID can be found by going to https://$syncroSubdomain.syncromsp.com/asset_types and click Manage Fields.
After clicking Manage Fields, you can see the asset type ID in the URL.
e.g https://$syncroSubdomain.syncromsp.com/asset_types/84342/asset_fields
#>
$syncroAssetTypeID = '84342'
##### END SyncroMSP Settings #####

########## DO NOT CHANGE ANYTHING BELOW HERE ##########

##### BEGIN Connectwise Control Functions #####
# Make sure $controlServer has HTTPS
if ($controlServer -notmatch 'https://') {
    Write-Output "`nProvided URL: $controlServer"
    Write-Output "HTTPS is required. Exiting.`n"
    Exit 1
}

function connectToControl {
    # Hide progress to make Invoke-WebRequest a bit faster
    $ProgressPreference = 'SilentlyContinue'
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

function getControlSessions {
    Write-Host -ForegroundColor Green "Getting sessions from Connectwise Control..."
    $body = '[2,["All Machines"],"",null,null,null]'
    $controlResponse = Invoke-RestMethod -Headers $($controlServerConnection.Headers) -Method POST -Uri "$controlServer/Services/PageService.ashx/GetHostSessionInfo" -Body $body
    return $controlResponse.sessions | Sort-Object Name
}

##### END Connectwise Control Functions #####

###### BEGIN SyncroMSP Functions ######
$headers = @{
    "Authorization" = "$syncroAPIToken"
    "Accept" = "application/json"
}

$syncroURLBase = "https://$syncroSubdomain.syncromsp.com/api/v1"

function getSyncroAssets {
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
##### END SyncroMSP Functions #####

##### BEGIN Comparison Functions #####
# Compare the customer lists and select matching companies
function getMutualCompanies {
    $mutualCompanies = @()
        foreach ($company in $syncroCustomers) {
            if ($controlCompanies -contains $company) {
                $mutualCompanies += $company
        }
    } return $mutualCompanies
}

function filterControlSessions {
    # Get the Control sessions for companies that exist in both Syncro and Control
    $filteredControlSessions = @()
    foreach ($session in $controlSessions) {
        if ($mutualCompanies -contains $($session.CustomPropertyValues[0])) {
            $filteredControlSessions += $session
        }
    } return $filteredControlSessions
}

function findMissingAssets {
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
    } return $missingAssets
}
##### END Comparions Functions #####

##### EXECUTION SECTION #####
connectToControl
$controlSessions = getControlSessions
$controlCompanies = $controlSessions | ForEach-Object { $_.CustomPropertyValues[0] } | Select-Object -Unique | Sort-Object

$syncroAssets = getSyncroAssets
$syncroCustomers = $syncroAssets.customer.business_then_name | Select-Object -Unique | Sort-Object

$mutualCompanies = getMutualCompanies
$filteredControlSessions = filterControlSessions

$missingAssets = findMissingAssets
$missingAssets | Sort-Object Company | Export-Csv $pathtoCSVReport -NoTypeInformation

Exit 0