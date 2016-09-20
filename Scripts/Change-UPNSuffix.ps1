Import-Module ActiveDirectory
 
 Get-ADUser -Filter {UserPrincipalName -like "*@ad.example.com"} -SearchBase "OU=SomeUserOu,DC=ad,DC=example,DC=com" |
 ForEach-Object {
     $UPN = $_.UserPrincipalName.Replace("ad.example.com","example.com")
     Set-ADUser $_ -UserPrincipalName $UPN
 }
