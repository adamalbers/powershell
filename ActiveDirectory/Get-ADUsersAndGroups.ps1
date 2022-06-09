Import-Module ActiveDirectory
$report = @()
#Collect all users
$users = Get-ADUser -Filter * -Properties * -ResultSetSize $Null | Where-Object { $_.Enabled -eq "True" }
# Use ForEach loop, as we need group membership for every account that is collected.
# MemberOf property of User object has the list of groups and is available in DN format.
foreach ($user in $users) {
    $userGroupCollection = $user.MemberOf
    #This Array will hold Group Names to which the user belongs.
    $userGroupMembership = @()
    #To get the Group Names from DN format we will again use Foreach loop to query every DN and retrieve the Name property of Group.
    foreach ($userGroup in $userGroupCollection) {
        $groupDetails = Get-ADGroup -Identity $userGroup
        #Here we will add each group Name to UserGroupMembership array
        $userGroupMembership += $groupDetails.Name
    }
    # As the $userGroupMembership is array we need to join element with ‘,’ as the seperator
    $groups = $userGroupMembership -join ','
    # Create custom object
    $userObject = New-Object PSObject
    $userObject | Add-Member -MemberType noteproperty -Name Name -Value $user.Name
    $userObject | Add-Member -MemberType noteproperty -Name UserName -Value $user.SamAccountName
    $userObject | Add-Member -MemberType noteproperty -Name LastLogonDate -Value $user.LastLogonDate
    $userObject | Add-Member -MemberType noteproperty -Name Groups -Value $groups
    $report += $userObject
}
# Output to screen as well as csv file.
$report | Sort-Object Name | Format-Table -AutoSize
$report | Sort-Object Name | Export-Csv -Path "$Env:Temp\users.csv" -NoTypeInformation

Exit 0