$reportDirectory = 'C:\path\to\reports'
$today = (Get-Date -Format yyyy-MM-dd)
$csvPath = "$($reportDirectory)\$($today)-groupMembers.csv"
$jsonPath = "$($reportDirectory)\$($today)-groupMembers.json"

# Create our $reportDirectory if it does not exist
if (-not (Test-Path $reportDirectory -ErrorAction 'SilentlyContinue')) {
    New-Item $reportDirectory -ItemType Directory -Force | Out-Null
}

Import-Module ActiveDirectory
$report = @()

$groups = Get-ADGroup -Filter * -Properties * | Sort-Object Name
$users = Get-ADUser -Filter * -Properties * | Where-Object { $_.Enabled -eq $true } | Sort-Object Name

Write-Output "This script only shows group members that are user accounts."
Write-Output "It will NOT show computer accounts or nested group memberships."

foreach ($group in $groups) {
    $members = ($users | Where-Object { $_.MemberOf -match $group }).SamAccountName

    if ($members) {
        
        $memberNameCollection = @()
        $memberSamAccountNameCollection = @()
        $memberEmailCollection = @()
    
        foreach ($member in $members) {
            $memberDetails = $users | Where-Object { $_.SamAccountName -eq $member } | Select-Object *
            $memberName = $($memberDetails.Name)
            $memberSamAccountName = $($memberDetails.SamAccountName)
            $memberEmail = $($memberDetails.EmailAddress)

            if (-not $memberEmail) {
                $memberEmail = 'no email'
            }
            
            $memberNameCollection += $memberName
            $memberSamAccountNameCollection += $memberSamAccountName
            $memberEmailCollection += $memberEmail
        }

        $groupObject = New-Object -TypeName PSObject
        $groupObject | Add-Member -NotePropertyName GroupName -NotePropertyValue $($group.Name)
        $groupObject | Add-Member -NotePropertyName MemberNames -NotePropertyValue $memberNameCollection
        $groupObject | Add-Member -NotePropertyName SamAccountNames -NotePropertyValue $memberSamAccountNameCollection
        $groupObject | Add-Member -NotePropertyName EmailAddresses -NotePropertyValue $memberEmailCollection
        $report += $groupObject
    }
}

$report = $report | Sort-Object GroupName

# Export to a json file. This makes it easy to import into Powershell on another machine.
$report | ConvertTo-Json | Out-File "$jsonPath"

# Create formatting for CSV export
# When imported to Excel, this will have column A as the group name, with columns B, C, and D being lists of the members of that column A group.
$reportCSV = $report | `
    Select-Object GroupName, `
@{Name = 'MemberNames'; Expression = { $_.MemberNames -join "`r`n" } }, `
@{Name = 'SamAccountNames'; Expression = { $_.SamAccountNames -join "`r`n" } }, `
@{Name = 'EmailAddresses'; Expression = { $_.EmailAddresses -join "`r`n" } }

# Export to CSV (Use Excel to import the CSV and convert it to a table)
$reportCSV | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "Done."
Write-Output "CSV saved to $csvPath"
Write-Output "JSON saved to $jsonPath"

Exit 0