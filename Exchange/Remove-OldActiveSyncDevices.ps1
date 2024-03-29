#Removes ActiveSync devices that haven't synced in over X days (change number after AddDays in $DevicesToRemove declaration)

$DevicesToRemove = Get-ActiveSyncDevice -result unlimited | Get-ActiveSyncDeviceStatistics | Where-Object { $_.LastSuccessSync -le (Get-Date).AddDays('-60') }

$DevicesToRemove | ForEach-Object { Remove-ActiveSyncDevice ([string]$_.Guid) -Confirm:$false }

Exit 0