# Connect to Office365 using PowerShell to allow PS management of mailboxes, etc.
 $credentials = Get-Credential
 $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credentials -Authentication Basic -AllowRedirection
