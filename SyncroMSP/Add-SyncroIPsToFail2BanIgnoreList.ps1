# Use a read-only API token.
$syncroSubdomain = 'example'
$syncroAPIToken = 'aaaaBBBBccccDDDDeeee'
<# 
This is our ID for the asset type Syncro Device. It may be different for other Syncro customers.
Asset type ID can be found by going to https://$syncroSubdomain.syncromsp.com/asset_types and click Manage Fields.
After clicking Manage Fields, you can see the asset type ID in the URL.
e.g https://$syncroSubdomain.syncromsp.com/asset_types/84342/asset_fields
#>
$syncroAssetTypeID = '84342'

# Add allowed hostnames and IPs here for things that aren't part of Syncro assets (e.g., your SIP trunk IPs or any WAN IPs that contain only phones and not Syncro assets)
$pbxAllowListIPs = '127.0.0.1/8'

# fail2ban jail config file to modify on server. This should NOT be the production jail.conf
$jailConfPath = '/home/user/jail.conf.d/jail.conf'

###### DO NOT CHANGE ANYTHING BELOW THIS LINE #########

$headers = @{
    'Authorization' = "$syncroAPIToken"
    'Accept'        = 'application/json'
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

    Write-Host -ForegroundColor Green 'Getting assets from Syncro...'

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

$assets = getSyncroAssets

# Get WAN IPs for every asset in any customer that has the FFP PBX box checked in Syncro.
$pbxCustomerIPs = ($assets | Where-Object { $_.customer.properties.'FFP PBX (Fusion+Flowroute)' -eq '1' }).properties.kabuto_information.general.ip | Select-Object -Unique | Sort-Object

foreach ($ip in $pbxCustomerIPs) {
    # The leading space before $ip is necessary and is not a typo.
    $pbxAllowListIPs += " $ip"
}

$pbxAllowListIPs = $pbxAllowListIPs | Sort-Object

# SSH to server, replace the 'ignoreip =' line in $jailConfPath
$date = (Get-Date -Format yyyy-MM-dd_hh_ss).ToString()
& ssh -t ampsys@ampsys-pbx.ampsyscloud.com "cp $jailConfPath $jailConfPath-$date.bak`;sed -i \`"s#ignoreip =.*#ignoreip = $pbxAllowListIPs#g\`" $jailConfPath"

Exit 0