​​​​​​​Remove-Item "$env:windir/Temp/*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:systemdrive/Users/*/AppData/Local/Temp/*" -Recurse -Force -ErrorAction SilentlyContinue