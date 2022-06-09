# You may use country names or their ISO2 country code. E.g., North Korea or KP, Russia or RU
$countriesToBlock = @('China', 'Russia', 'Iran', 'North Korea', 'Pakistan', 'Romania', 'Belarus')

# The firewall rule names will all be prepnded with $ruleNamePrefix. The 'z' in mine is so they'll be at the bottom alphabetically.
# Make sure the $ruleNamePrefix is sufficiently distinct as this script will delete and replace the existing rules with this name.
$ruleNamePrefix = "z-BlockList"

# Description will be seen in the properties of the firewall rules.
$description = "Rule created by script on $(Get-Date -Format yyyy-MM-dd). Do not manually edit this rule."

##### DO NOT EDIT BELOW THIS LINE #####
$blocklistFile = "$Env:Temp\$ruleNamePrefix.txt"

# Remove existing blocklist file if it exists
Remove-Item $blocklistFile -Force -Confirm:$false -ErrorAction SilentlyContinue

# Download JSON file with all countries including their names and ISO2 codes among other things.
$countryDB = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries.json'

# Loop through countries and find their ISO2 code if needed and then download the CIDR list.
foreach ($country in $countriesToBlock) {
    if ($country.Length -eq 2) {
        $iso2 = $country.ToLower()
        $country = ($countryDB | Where-Object { $_.iso2 -eq "$country" }).Name
    }
    else {
        $iso2 = ($countryDB | Where-Object { $_.Name -match "$country" }).iso2.ToLower()
    }
    
    if ($iso2.Count -ne 1) {
        Write-Warning "More than one ISO2 country code found for `"$country`". Skipping this country."
    }
    else {
        Add-Content -Path $blocklistFile -Value "#$country"
        Invoke-RestMethod -Uri "https://www.ipdeny.com/ipblocks/data/aggregated/$iso2-aggregated.zone" | Add-Content -Path $blocklistFile
    }    
}

# Create array of IP ranges.  Any line that doesn't start like an IPv4/IPv6 address is ignored.
# When a blank line is trimmed of all space characters, it's length will be zero.
# The regex pattern looks for 1 to 4 numbers or hex letters, followed by a period or colon.
$ranges = Get-Content $blocklistFile | Where-Object { ($_.Trim().Length -ne 0) -and ($_ -Match '^[0-9a-f]{1,4}[\.\:]') } 
$rangeCount = $ranges.Count

# Confirm that the InputFile had at least one IP address or IP range to block.
if ($rangeCount -eq 0) { 
    "`n$blocklistFile contained no IP addresses to block, quitting...`n"
    Exit 
}

# Now start creating rules with hundreds of IP address ranges per rule.  Testing shows
# that errors begin to occur with more than 400 IPv4 ranges per rule, and this 
# number might still be too large when using IPv6 or the Start-to-End format, so 
# default to only 200 ranges per rule, but feel free to edit the following variable
# to change how many IP address ranges are included in each firewall rule:

$maxRangesPerRule = 200

# Create a new array to hold the groups of ranges of size $maxRangesPerRule
$groupsOfRanges = @()
$numberOfGroups = [math]::Ceiling($ranges.Length / $maxRangesPerRule)
 
# Separate $ranges into groups of $maxRangesPerRule and store them in $groupsOfRanges
for ($i = 0; $i -le $numberOfGroups; $i++) {
    $start = $i * $maxRangesPerRule
    $end = (($i + 1) * $maxRangesPerRule) - 1
    $groupsOfRanges += , @($ranges[$start..$end])
}

# Delete any existing firewall rules which match the rule name.
Get-NetFirewallRule | Where-Object { ($_.DisplayName -match "$ruleNamePrefix") } | Remove-NetFirewallRule

# Set starting rule number that will be appended to $ruleNamePrefix
$ruleNumber = 0

# Create firewall rules
$groupsOfRanges | ForEach-Object {
    $ruleNumber++
    $numberString = $ruleNumber.ToString().PadLeft(3, "0")

    $remoteIPs = $_
    
    # Make sure we only make a rule if $remoteIPs is populated, or we'll accidentally make a rule that blocks any/any.
    if ($remoteIPs) {
        # Create the inbound rule to block the IP ranges selected.
        New-NetFirewallRule -DisplayName "$ruleNamePrefix-$numberString" -Direction Inbound -Action Block -LocalAddress Any -RemoteAddress $remoteIPs -Description $description | Out-Null
  
        # Create the outbound rule to block the IP ranges selected.
        New-NetFirewallRule -DisplayName "$ruleNamePrefix-$numberString" -Direction Outbound -Action Block -LocalAddress Any -RemoteAddress $remoteIPs -Description $description | Out-Null
    }
    
}

# Cleanup
Remove-Item $blocklistFile -Force -Confirm:$false

Exit 0