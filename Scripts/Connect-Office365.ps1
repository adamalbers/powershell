# Connect to Office365 using PowerShell to allow PS management of mailboxes, etc.
$session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
Import-PSSession $session365