#Run this from Exchange Shell. This returns all SMTP addresses, as opposed to just the primary.
Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, Server, PrimarySmtpAddress, @{Name = “EmailAddresses”; Expression = { $_.EmailAddresses | Where-Object { $_.PrefixString -ceq “smtp” } | ForEach-Object { $_.SmtpAddress } } } | Sort-Object DisplayName | Format-Table -Auto
