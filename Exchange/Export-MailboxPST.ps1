<#
.SYNOPSIS
    This script will dump Calendar and Contacts folders to PSTs.
.DESCRIPTION
    Script created for exporting calender and Contacts. Primarily used
    for IMAP migrations that do not handle calendar or contact items.
    If possible, this PST method should be avoided for a proper
    Exchange migration.
.NOTES
    File Name  : Export-MailboxPST.ps1
    Author     : Adam Albers
.LINK
    https://github.com/adamalbers
    https://github.com/adamalbers/powershell/blob/master/scripts/Export-MailboxPST.ps1
#>

# Set your PST path here. Must be UNC with trailing backslash (\).
$pstPath = '\\unc\path\to\share\'

# Get mailbox aliases and sort them alphabetically
$mailboxes = Get-Mailbox -ResultSize Unlimited | select -ExpandProperty alias | Sort

<#
Export Calendar and Contacts for each mailbox. If there is an existing PST for that mailbox, it will just be updated with new items.
The # around the folder name picks the Calendar folder regardless of translation to another language. If you modify this for user created folders, remove the #.

-ExcludeDumpster is important to avoid grabbing the Deleted Items folder.
#>
foreach ($mailbox in $mailboxes) {
    New-MailboxExportRequest $mailbox -FilePath "$pstPath$mailbox.pst" -IncludeFolders '#Calendar#', '#Contacts#' -ExcludeDumpster
}

Exit 0