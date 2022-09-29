# This will use Keeper Commander (CLI) to export all the records in Keeper to a KeePass database file.

#---- DO NOT MODIFY BELOW THIS LINE ----#
$config = Import-Config keeperBackup.json.secret

$today = (Get-Date -Format yyyy-MM-dd).toString()
$backupDest = "$($config.DestinationDir)/$($today)-keeper.kdbx"

Start-Process -Path $($config.keeperCliPath) -ArgumentList "--config `"$($config.keeperConfig)`" export `"$backupDest`"  --format keepass --keepass-file-password=`"$($config.keepassFilePassword)`" --force" -NoNewWindow

Exit 0