Import-Module ActiveDirectory
$Report = @()
#Collect all users
$Users = Get-ADUser -Filter * -Properties * -ResultSetSize $Null | Where-Object {$_.Enabled -eq "True"}
# Use ForEach loop, as we need group membership for every account that is collected.
# MemberOf property of User object has the list of groups and is available in DN format.
Foreach ($User in $users) {
    $UserGroupCollection = $User.MemberOf
    #This Array will hold Group Names to which the user belongs.
    $UserGroupMembership = @()
    #To get the Group Names from DN format we will again use Foreach loop to query every DN and retrieve the Name property of Group.
    Foreach ($UserGroup in $UserGroupCollection) {
        $GroupDetails = Get-ADGroup -Identity $UserGroup
        #Here we will add each group Name to UserGroupMembership array
        $UserGroupMembership += $GroupDetails.Name
    }
    #As the UserGroupMembership is array we need to join element with ‘,’ as the seperator
    $Groups = $UserGroupMembership -join ','
    #Creating custom objects
    $Out = New-Object PSObject
    $Out | Add-Member -MemberType noteproperty -Name Name -Value $User.Name
    $Out | Add-Member -MemberType noteproperty -Name UserName -Value $User.SamAccountName
    $Out | Add-Member -MemberType noteproperty -Name LastLogonDate -Value $User.LastLogonDate
    $Out | Add-Member -MemberType noteproperty -Name Groups -Value $Groups
    $Report += $Out
}
#Output to screen as well as csv file.
$Report | Sort-Object Name | FT -AutoSize
$Report | Sort-Object Name | Export-Csv -Path "$Env:Temp\users.csv" -NoTypeInformation

Exit 0